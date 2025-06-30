import SwiftUI
import FirebaseFirestore

struct TradeOffersView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var tradeService: TradeService
    @EnvironmentObject var bookService: BookService
    
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedOfferId: String?
    @State private var selectedAction: TradeAction?
    @State private var showingRatingSheet = false
    
    enum TradeAction {
        case accept, reject, complete, cancelComplete, delete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Material design arka planı
                ThemeColors.background
                    .ignoresSafeArea()
                
                VStack {
                    // Modern segmented control
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ThemeColors.secondaryBackground.opacity(0.6))
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            .frame(height: 46)
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 0
                                    loadTradeOffers()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "tray.and.arrow.down")
                                        .font(.caption)
                                    Text("Alınan")
                                        .fontWeight(selectedTab == 0 ? .semibold : .medium)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedTab == 0 ? 
                                    ThemeColors.primaryText : 
                                    ThemeColors.secondaryText)
                            }
                            .background(
                                Group {
                                    if selectedTab == 0 {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [ThemeColors.primary.opacity(0.9), ThemeColors.accent.opacity(0.85)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 3, x: 0, y: 2)
                                    }
                                }
                            )
                            .cornerRadius(10)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 1
                                    loadTradeOffers()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "tray.and.arrow.up")
                                        .font(.caption)
                                    Text("Gönderilen")
                                        .fontWeight(selectedTab == 1 ? .semibold : .medium)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedTab == 1 ? 
                                    ThemeColors.primaryText : 
                                    ThemeColors.secondaryText)
                            }
                            .background(
                                Group {
                                    if selectedTab == 1 {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [ThemeColors.primary.opacity(0.9), ThemeColors.accent.opacity(0.85)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 3, x: 0, y: 2)
                                    }
                                }
                            )
                            .cornerRadius(10)
                        }
                        .padding(4)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView("Yükleniyor...")
                            .padding()
                            .tint(ThemeColors.accent)
                        Spacer()
                    } else {
                        // Seçilen sekmeye göre teklifleri göster
                        TabView(selection: $selectedTab) {
                            // Alınan Teklifler
                            receivedTradeOffersView
                                .tag(0)
                                .padding(.top)
                            
                            // Gönderilen Teklifler
                            sentTradeOffersView
                                .tag(1)
                                .padding(.top)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("Takas Teklifleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                    startPoint: .leading,
                    endPoint: .trailing
                ), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadTradeOffers()
            }
            .refreshable {
                await refreshOffers()
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("Tamam")) {
                        if selectedAction != nil {
                            handleTradeAction()
                        }
                    },
                    secondaryButton: .cancel {
                        selectedOfferId = nil
                        selectedAction = nil
                    }
                )
            }
            .sheet(isPresented: $showingRatingSheet) {
                if let offerId = selectedOfferId,
                   let offer = (selectedTab == 0 ? tradeService.receivedOffers : tradeService.sentOffers).first(where: { $0.id == offerId }) {
                    
                    let targetUserId = selectedTab == 0 ? offer.offererId : offer.receiverId
                    RatingView(targetUserId: targetUserId, bookId: offer.requestedBookId, offerId: offerId)
                        .environmentObject(authService)
                }
            }
        }
        .accentColor(ThemeColors.primary)
    }
    
    // Async/await ile takas tekliflerini yenile
    private func refreshOffers() async {
        guard let userId = authService.user?.id else { return }
        
        do {
            // Alınan ve gönderilen teklifleri asenkron olarak yükle
            let receivedOffers = try await tradeService.getReceivedTradeOffersAsync(userId: userId)
            let sentOffers = try await tradeService.getSentTradeOffersAsync(userId: userId)
            
            // UI güncellemelerini main thread'de yapmalıyız
            DispatchQueue.main.async {
                tradeService.receivedOffers = receivedOffers
                tradeService.sentOffers = sentOffers
                
                // Tamamlanmış teklifleri filtrele
                tradeService.filterCompletedOffers()
                
                tradeService.pendingReceivedCount = receivedOffers.filter { $0.status == "pending" }.count
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                tradeService.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // Alınan teklifler görünümü
    private var receivedTradeOffersView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if tradeService.receivedOffers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(.bottom, 10)
                        
                        Text("Henüz takas teklifi almadınız.")
                            .font(.headline)
                            .foregroundColor(ThemeColors.secondaryText)
                        
                        Text("Diğer kullanıcılar kitaplarınıza ilgi gösterdiğinde takas teklifleri burada görünecek.")
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.tertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        NavigationLink(destination: HomeView()) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.footnote)
                                Text("Takas Kitaplarını Keşfet")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .foregroundColor(.white)
                            .shadow(color: ThemeColors.primary.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(tradeService.receivedOffers) { offer in
                        TradeOfferCard(offer: offer, isReceived: true, onActionTap: { action in
                            selectedOfferId = offer.id
                            selectedAction = action
                            
                            switch action {
                            case .accept:
                                alertTitle = "Teklifi Kabul Et"
                                alertMessage = "Bu takas teklifini kabul etmek istediğinize emin misiniz?"
                                showingAlert = true
                            case .reject:
                                alertTitle = "Teklifi Reddet"
                                alertMessage = "Bu takas teklifini reddetmek istediğinize emin misiniz?"
                                showingAlert = true
                            case .complete:
                                alertTitle = "Takası Tamamla"
                                alertMessage = "Takasın tamamlandığını onaylıyor musunuz?"
                                showingAlert = true
                            case .cancelComplete:
                                alertTitle = "Takası İptal Et"
                                alertMessage = "Tamamlama işlemini iptal etmek istediğinize emin misiniz?"
                                showingAlert = true
                            case .delete:
                                alertTitle = "Teklifi Sil"
                                alertMessage = "Bu takas teklifini silmek istediğinize emin misiniz?"
                                showingAlert = true
                            }
                        })
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Gönderilen teklifler görünümü
    private var sentTradeOffersView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if tradeService.sentOffers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.accent, ThemeColors.primary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: ThemeColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(.bottom, 10)
                        
                        Text("Henüz takas teklifi göndermediniz.")
                            .font(.headline)
                            .foregroundColor(ThemeColors.secondaryText)
                        
                        Text("İlgilendiğiniz kitaplara takas teklifi gönderdiğinizde burada listelenecek.")
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.tertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        NavigationLink(destination: HomeView()) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.footnote)
                                Text("Kitapları Keşfet")
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.accent, ThemeColors.primary]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .foregroundColor(.white)
                            .shadow(color: ThemeColors.accent.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(tradeService.sentOffers) { offer in
                        TradeOfferCard(offer: offer, isReceived: false, onActionTap: { action in
                            selectedOfferId = offer.id
                            selectedAction = action
                            
                            switch action {
                            case .complete:
                                alertTitle = "Takası Tamamla"
                                alertMessage = "Takasın tamamlandığını onaylıyor musunuz?"
                                showingAlert = true
                            case .cancelComplete:
                                alertTitle = "Takası İptal Et"
                                alertMessage = "Tamamlama işlemini iptal etmek istediğinize emin misiniz?"
                                showingAlert = true
                            case .delete:
                                alertTitle = "Teklifi Geri Çek"
                                alertMessage = "Bu takas teklifini geri çekmek istediğinize emin misiniz?"
                                showingAlert = true
                            default:
                                break
                            }
                        })
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Takas tekliflerini yükle
    private func loadTradeOffers() {
        guard let userId = authService.user?.id else { return }
        
        isLoading = true
        
        // Alınan teklifleri yükle
        tradeService.getReceivedTradeOffers(userId: userId)
        
        // Gönderilen teklifleri yükle
        tradeService.getSentTradeOffers(userId: userId)
        
        // Bekleyen takas tekliflerini dinlemeye başla
        tradeService.listenForPendingOffers(userId: userId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Tamamlanmış teklifleri filtrele
            self.tradeService.filterCompletedOffers()
            self.isLoading = false
        }
    }
    
    // Takas aksiyonlarını işle
    private func handleTradeAction() {
        guard let offerId = selectedOfferId, let action = selectedAction else { return }
        
        isLoading = true
        
        switch action {
        case .accept:
            tradeService.updateTradeOfferStatus(id: offerId, status: "accepted") { success in
                isLoading = false
                if !success {
                    alertTitle = "Hata"
                    alertMessage = "Teklifin durumu güncellenirken bir hata meydana geldi."
                    showingAlert = true
                } else {
                    loadTradeOffers()
                }
            }
            
        case .reject:
            tradeService.updateTradeOfferStatus(id: offerId, status: "rejected") { success in
                isLoading = false
                if !success {
                    alertTitle = "Hata"
                    alertMessage = "Teklifin durumu güncellenirken bir hata meydana geldi."
                    showingAlert = true
                } else {
                    loadTradeOffers()
                }
            }
            
        case .complete:
            if let offer = (selectedTab == 0 ? tradeService.receivedOffers : tradeService.sentOffers).first(where: { $0.id == offerId }) {
                // Teklif sahibiyse
                if selectedTab == 1 {
                    tradeService.updateTradeOffer(id: offerId, data: ["offererConfirmed": true]) { success in
                        handleCompleteResult(success, offer: offer)
                    }
                } else {
                    // Teklif alıcısıysa
                    tradeService.updateTradeOffer(id: offerId, data: ["receiverConfirmed": true]) { success in
                        handleCompleteResult(success, offer: offer)
                    }
                }
            }
            
        case .cancelComplete:
            if let offer = (selectedTab == 0 ? tradeService.receivedOffers : tradeService.sentOffers).first(where: { $0.id == offerId }) {
                // Teklif sahibiyse
                if selectedTab == 1 {
                    tradeService.updateTradeOffer(id: offerId, data: ["offererConfirmed": false]) { success in
                        isLoading = false
                        if !success {
                            alertTitle = "Hata"
                            alertMessage = "Teklif güncellenirken bir hata meydana geldi."
                            showingAlert = true
                        } else {
                            loadTradeOffers()
                        }
                    }
                } else {
                    // Teklif alıcısıysa
                    tradeService.updateTradeOffer(id: offerId, data: ["receiverConfirmed": false]) { success in
                        isLoading = false
                        if !success {
                            alertTitle = "Hata"
                            alertMessage = "Teklif güncellenirken bir hata meydana geldi."
                            showingAlert = true
                        } else {
                            loadTradeOffers()
                        }
                    }
                }
            }
            
        case .delete:
            tradeService.deleteTradeOffer(id: offerId) { success in
                isLoading = false
                if !success {
                    alertTitle = "Hata"
                    alertMessage = "Teklif silinirken bir hata meydana geldi."
                    showingAlert = true
                } else {
                    loadTradeOffers()
                }
            }
        }
        
        // Aksiyon tamamlandıktan sonra seçimleri temizle
        selectedOfferId = nil
        selectedAction = nil
    }
    
    // Tamamlama sonucunu işleme
    private func handleCompleteResult(_ success: Bool, offer: TradeOffer) {
        if success {
            // Güncelleme sonrası en son offer durumunu yeniden çekelim
            tradeService.getTradeOffer(id: offer.id ?? "") { updatedOffer in
                guard let updatedOffer = updatedOffer else {
                    self.isLoading = false
                    self.loadTradeOffers()
                    return
                }
                
                // Her iki taraf da onayladıysa takas tamamlanmış demektir
                if let offererConfirmed = updatedOffer.offererConfirmed, 
                   let receiverConfirmed = updatedOffer.receiverConfirmed,
                   offererConfirmed && receiverConfirmed {
                    
                    // Takas durumunu tamamlandı olarak güncelle
                    self.tradeService.updateTradeOfferStatus(id: updatedOffer.id ?? "", status: "completed") { statusSuccess in
                        if statusSuccess {
                            // Her iki kitabın durumunu güncelle
                            self.updateBookStatus(bookId: updatedOffer.offeredBookId, status: "sold") {
                                self.updateBookStatus(bookId: updatedOffer.requestedBookId, status: "sold") {
                                    // Takası tamamladıktan sonra puan ver
                                    self.selectedOfferId = updatedOffer.id
                                    self.showingRatingSheet = true
                                    self.isLoading = false
                                    
                                    // Her iki tarafa da takas tamamlandı bildirimi gönder
                                    self.sendCompletionNotification(offer: updatedOffer)
                                    
                                    // Listeyi yenile
                                    self.loadTradeOffers()
                                }
                            }
                        } else {
                            self.isLoading = false
                            self.alertTitle = "Hata"
                            self.alertMessage = "Takas tamamlanırken bir hata meydana geldi."
                            self.showingAlert = true
                        }
                    }
                } else {
                    self.isLoading = false
                    self.loadTradeOffers()
                }
            }
        } else {
            isLoading = false
            alertTitle = "Hata"
            alertMessage = "Teklif güncellenirken bir hata meydana geldi."
            showingAlert = true
        }
    }
    
    // Kitap durumunu güncelle
    private func updateBookStatus(bookId: String, status: String, completion: @escaping () -> Void) {
        bookService.updateBookStatus(bookId: bookId, status: status) { success in
            if !success {
                print("Kitap durumu güncellenirken hata: \(bookId)")
                // Hata olsa bile devam edelim, kritik bir durum değil
            }
            completion()
        }
    }
    
    // Takas tamamlandı bildirimi gönderme
    private func sendCompletionNotification(offer: TradeOffer) {
        // Takas tamamlandı mesajı
        let completionMessage = "Takas işlemi başarıyla tamamlandı. Her iki taraf da kitapların takasını onayladı."
        
        // Uygulama içi bildirim oluştur
        let notification = [
            "type": "trade_completed",
            "offerId": offer.id ?? "",
            "message": completionMessage,
            "createdAt": Date()
        ] as [String: Any]
        
        // Her iki tarafa da bildirim gönder
        let db = Firestore.firestore()
        
        // Teklifi yapan kişiye bildirim
        let offererNotification = notification.merging(["userId": offer.offererId], uniquingKeysWith: { (current, _) in current })
        db.collection("notifications").addDocument(data: offererNotification)
        
        // Teklifi alan kişiye bildirim
        let receiverNotification = notification.merging(["userId": offer.receiverId], uniquingKeysWith: { (current, _) in current })
        db.collection("notifications").addDocument(data: receiverNotification)
    }
}

// Takas teklifi kartı
struct TradeOfferCard: View {
    let offer: TradeOffer
    let isReceived: Bool
    let onActionTap: (TradeOffersView.TradeAction) -> Void
    
    @EnvironmentObject var bookService: BookService
    
    @State private var offeredBook: Book?
    @State private var requestedBook: Book?
    @State private var isLoading = true
    
    var statusColor: Color {
        switch offer.status {
        case "pending":
            return ThemeColors.warning
        case "accepted":
            return ThemeColors.info
        case "rejected":
            return ThemeColors.error
        case "completed":
            return ThemeColors.success
        default:
            return ThemeColors.secondary
        }
    }
    
    var statusText: String {
        switch offer.status {
        case "pending":
            return "Beklemede"
        case "accepted":
            return "Kabul Edildi"
        case "rejected":
            return "Reddedildi"
        case "completed":
            return "Tamamlandı"
        default:
            return "Bilinmiyor"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Durum başlığı
            HStack {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
                    .foregroundColor(statusColor)
                    .overlay(
                        Capsule()
                            .stroke(statusColor.opacity(0.4), lineWidth: 1)
                    )
                
                Spacer()
                
                Text(formatDate(offer.createdAt))
                    .font(.caption)
                    .foregroundColor(ThemeColors.tertiaryText)
            }
            .padding(.bottom, 4)
            
            // Kitap bilgileri
            if isLoading {
                ProgressView("Kitap bilgileri yükleniyor...")
                    .padding()
                    .tint(ThemeColors.accent)
            } else {
                VStack(spacing: 14) {
                    // İstenen kitap
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isReceived ? "Sizin kitabınız:" : "İstenen kitap:")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(ThemeColors.secondaryText)
                            .padding(.leading, 4)
                        
                        if let book = requestedBook {
                            bookRow(book: book)
                                .transition(.opacity)
                        } else {
                            Text("Kitap bilgileri yüklenemedi")
                                .font(.subheadline)
                                .foregroundColor(ThemeColors.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(ThemeColors.secondaryBackground.opacity(0.7))
                                )
                                .cornerRadius(12)
                        }
                    }
                    
                    // Teklif edilen kitap
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isReceived ? "Teklif edilen kitap:" : "Sizin kitabınız:")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(ThemeColors.secondaryText)
                            .padding(.leading, 4)
                        
                        if let book = offeredBook {
                            bookRow(book: book)
                                .transition(.opacity)
                        } else {
                            Text("Kitap bilgileri yüklenemedi")
                                .font(.subheadline)
                                .foregroundColor(ThemeColors.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(ThemeColors.secondaryBackground.opacity(0.7))
                                )
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // İleti varsa göster
            if let message = offer.message, !message.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mesaj:")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Text(message)
                        .font(.subheadline)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ThemeColors.secondaryBackground.opacity(0.6))
                        )
                        .cornerRadius(12)
                        .foregroundColor(ThemeColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // İşlem düğmeleri
            HStack(spacing: 10) {
                // Duruma göre farklı butonlar göster
                if offer.status == "pending" {
                    if isReceived {
                        // Alıcı için butonlar
                        Button(action: { onActionTap(.accept) }) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                Text("Kabul Et")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.success, ThemeColors.success.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: ThemeColors.success.opacity(0.4), radius: 5, x: 0, y: 3)
                        }
                        
                        Button(action: { onActionTap(.reject) }) {
                            HStack {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                Text("Reddet")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.error, ThemeColors.error.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: ThemeColors.error.opacity(0.4), radius: 5, x: 0, y: 3)
                        }
                    } else {
                        // Gönderen için iptal butonu
                        Button(action: { onActionTap(.delete) }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.caption)
                                Text("İptal Et")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.error, ThemeColors.error.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: ThemeColors.error.opacity(0.4), radius: 5, x: 0, y: 3)
                        }
                    }
                } else if offer.status == "accepted" {
                    // Kabul edilmiş teklifler için tamamlama butonu
                    // Her iki taraf da onayladıysa onay butonunu göstermeyin
                    if let offererConfirmed = offer.offererConfirmed,
                       let receiverConfirmed = offer.receiverConfirmed,
                       offererConfirmed && receiverConfirmed {
                        
                        // Her iki taraf da onaylamış, tamamlanmış olarak göster
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ThemeColors.success)
                                    .font(.title3)
                                
                                Text("Takas tamamlandı")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ThemeColors.success)
                            }
                            
                            Text("İki taraf da takası onayladı. İşlem tamamlandı.")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        
                    // Sadece kendi tarafın onayladıysa, iptal etme seçeneği göster
                    } else if (isReceived && offer.receiverConfirmed == true) || (!isReceived && offer.offererConfirmed == true) {
                        VStack(spacing: 6) {
                            Text("Onayınız alındı")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeColors.info)
                            
                            Text("Diğer kullanıcının onayı bekleniyor")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                            
                            Button(action: { onActionTap(.cancelComplete) }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.caption)
                                    Text("Onayımı Geri Çek")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [ThemeColors.warning, ThemeColors.warning.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: ThemeColors.warning.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                        }
                    // Henüz onaylanmamışsa, onaylama butonu göster
                    } else {
                        Button(action: { onActionTap(.complete) }) {
                            HStack {
                                Image(systemName: "checkmark.seal")
                                    .font(.caption)
                                Text("Tamamlandı Olarak İşaretle")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.info, ThemeColors.info.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: ThemeColors.info.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                } else if offer.status == "rejected" {
                    // Sadece reddedilmiş teklifler için silme butonu
                    Button(action: { onActionTap(.delete) }) {
                        HStack {
                            Image(systemName: "xmark.bin")
                                .font(.caption)
                            Text("Teklifi Temizle")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [ThemeColors.secondary, ThemeColors.secondary.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: ThemeColors.secondary.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                } else if offer.status == "completed" {
                    // Tamamlanmış takaslar için bilgilendirme metni
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ThemeColors.success)
                                .font(.title3)
                            
                            Text("Takas başarıyla tamamlandı")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeColors.success)
                        }
                        
                        Text("Bu takas her iki taraftan da onaylanmıştır ve tamamlanmıştır.")
                            .font(.caption)
                            .foregroundColor(ThemeColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeColors.cardBackground.opacity(0.9))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [ThemeColors.primary.opacity(0.2), ThemeColors.accent.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            loadBookDetails()
        }
    }
    
    private func bookRow(book: Book) -> some View {
        NavigationLink(destination: BookDetailView(bookId: book.id ?? "")) {
            HStack {
                // Resim bölümü
                if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(12)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(ThemeColors.cardBackground.opacity(0.5))
                            .frame(width: 60, height: 90)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                                    .tint(ThemeColors.accent)
                            )
                    }
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 70)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [ThemeColors.primary.opacity(0.7), ThemeColors.accent.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(5)
                        .background(ThemeColors.secondaryBackground)
                        .cornerRadius(12)
                }
                
                // Kitap bilgileri
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                        .lineLimit(1)
                    
                    HStack {
                        Text("Durum:")
                            .font(.caption)
                            .foregroundColor(ThemeColors.tertiaryText)
                        Text(book.condition)
                            .font(.caption)
                            .foregroundColor(ThemeColors.accent)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Sağ ok işareti
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.7), ThemeColors.accent.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.cardBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.3), ThemeColors.accent.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(CustomButtonStyle())
    }
    
    private func loadBookDetails() {
        // Kitaplar zaten yüklenmişse tekrar yükleme
        if offeredBook != nil && requestedBook != nil {
            isLoading = false
            return
        }
        
        isLoading = true
        
        let dispatchGroup = DispatchGroup()
        
        // Teklif edilen kitap detaylarını yükle
        dispatchGroup.enter()
        bookService.fetchBookById(id: offer.offeredBookId) { book in
            defer { dispatchGroup.leave() }
            
            if let book = book {
                DispatchQueue.main.async {
                    self.offeredBook = book
                }
            } else {
                print("Teklif edilen kitap yüklenemedi: \(self.offer.offeredBookId)")
            }
        }
        
        // İstenen kitap detaylarını yükle
        dispatchGroup.enter()
        bookService.fetchBookById(id: offer.requestedBookId) { book in
            defer { dispatchGroup.leave() }
            
            if let book = book {
                DispatchQueue.main.async {
                    self.requestedBook = book
                }
            } else {
                print("İstenen kitap yüklenemedi: \(self.offer.requestedBookId)")
            }
        }
        
        // Her iki kitap da yüklendiğinde veya hata oluştuğunda
        dispatchGroup.notify(queue: .main) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.isLoading = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Özel buton stili
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
} 