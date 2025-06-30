import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var tradeService: TradeService
    @EnvironmentObject var chatService: ChatService
    @Environment(\.presentationMode) var presentationMode
    
    let bookId: String
    @State private var book: Book?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingTradeOfferSheet = false
    @State private var showingMessageSheet = false
    @State private var showingEditSheet = false
    @State private var showingActionSheet = false
    @State private var isOwnerOfBook = false
    @State private var currentImageIndex = 0
    @State private var showDeleteConfirmation = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            content
        }
        .background(ThemeColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let book = book, !isLoading {
                    Text("Kitap Detayları")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeColors.primaryText)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isOwnerOfBook, let book = book {
                    Menu {
                                Button(action: { showingEditSheet = true }) {
                                    Label("Düzenle", systemImage: "pencil")
                                }
                                
                                Button(action: { showingActionSheet = true }) {
                                    Label("Durum Değiştir", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Sil", systemImage: "trash")
                }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(ThemeColors.primary)
                            .padding(8)
                            .background(ThemeColors.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear {
            loadBook()
        }
        .sheet(isPresented: $showingTradeOfferSheet) {
            if let book = book {
                TradeOfferView(requestedBook: book)
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            if let book = book {
                NewMessageView(receiverId: book.ownerId, receiverName: book.ownerDisplayName, bookId: bookId, bookTitle: book.title)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let book = book {
                NavigationView {
                    AddBookView(editMode: true, bookToEdit: book)
                        .navigationTitle("Kitabı Düzenle")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .confirmationDialog("Kitap Durumu", isPresented: $showingActionSheet) {
            Button("Mevcut olarak işaretle") {
                updateBookStatus("available")
            }
            .foregroundColor(ThemeColors.success)
            
            Button("Rezerve olarak işaretle") {
                updateBookStatus("reserved")
            }
            .foregroundColor(ThemeColors.warning)
            
            Button("Satıldı/Takas edildi olarak işaretle") {
                updateBookStatus("sold")
            }
            .foregroundColor(ThemeColors.error)
            
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Kitabın durumunu değiştir")
        }
        .alert("Hata", isPresented: Binding<Bool>(
            get: { !errorMessage.isEmpty },
            set: { if !$0 { errorMessage = "" } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Kitabı Sil", isPresented: $showDeleteConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("Bu kitabı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if let book = book {
            bookDetailView(book: book)
        } else {
            notFoundView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
            
            Text("Kitap yükleniyor...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
        .background(ThemeColors.background)
    }
    
    private func bookDetailView(book: Book) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Kitap görselleri
            bookImagesView(book: book)
            
            VStack(alignment: .leading, spacing: 24) {
                // Başlık ve yazar
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ThemeColors.primaryText)
                        .lineSpacing(1.2)
                    
                    Text(book.author)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                // Kategori ve durum
                categoryAndConditionView(book: book)
                
                // Durum bilgisi
                statusView(book: book)
                
                Divider()
                    .background(ThemeColors.tertiaryText.opacity(0.3))
                    .padding(.vertical, 8)
                
                // Açıklama
                VStack(alignment: .leading, spacing: 12) {
                    Text("Açıklama")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(book.description)
                        .font(.system(size: 16))
                        .foregroundColor(ThemeColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(6)
                }
                
                Divider()
                    .background(ThemeColors.tertiaryText.opacity(0.3))
                    .padding(.vertical, 8)
                
                // Satıcı bilgisi
                ownerInfoView(book: book)
                
                // İşlem butonları (kitap sahibi değilse göster)
                if !isOwnerOfBook && book.status == "available" {
                    Divider()
                        .background(ThemeColors.tertiaryText.opacity(0.3))
                        .padding(.vertical, 8)
                    
                    actionButtonsView(book: book)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func bookImagesView(book: Book) -> some View {
        if book.imageURLs.isEmpty {
            ZStack {
                ThemeColors.secondaryBackground
                
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(ThemeColors.tertiaryText)
                    .padding(40)
            }
            .frame(height: 320)
            .cornerRadius(20)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else {
            TabView(selection: $currentImageIndex) {
                ForEach(0..<book.imageURLs.count, id: \.self) { index in
                    ZStack {
                        // Arka plan ve yükleniyor göstergesi
                        ThemeColors.secondaryBackground
                        
                        ProgressView()
                            .scaleEffect(1.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
                        
                        // Asenkron görüntü
                        if let imageUrl = URL(string: book.imageURLs[index]) {
                            AsyncImage(url: imageUrl) { phase in
                                switch phase {
                                case .empty:
                                    Color.clear // Zaten arka planda loading var
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(ThemeColors.secondaryBackground)
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(ThemeColors.tertiaryText)
                                        
                                        Text("Görüntü yüklenemedi")
                                            .font(.system(size: 14))
                                            .foregroundColor(ThemeColors.tertiaryText)
                                        
                                        Button(action: {
                                            // Yeniden yükleme mantığı
                                            loadBook()
                                        }) {
                                            Text("Yeniden Dene")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(ThemeColors.primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 360)
            .cornerRadius(20)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                HStack {
                    Text("\(currentImageIndex + 1) / \(book.imageURLs.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ThemeColors.primary.opacity(0.8))
                        .cornerRadius(20)
                        .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom),
                alignment: .bottomTrailing
            )
        }
    }
    
    private func categoryAndConditionView(book: Book) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.primary)
                
                Text(book.category)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ThemeColors.primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ThemeColors.primary.opacity(0.15))
            .cornerRadius(12)
            
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.info)
                
                Text(book.condition)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ThemeColors.primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ThemeColors.info.opacity(0.15))
            .cornerRadius(12)
        }
    }
    
    private func statusView(book: Book) -> some View {
        HStack(spacing: 16) {
            if book.isForSale {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text(book.price != nil ? "\(book.price!) TL" : "Satılık")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.15))
                .cornerRadius(12)
            }
            
            if book.isForTrade {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.primary)
                    
                    Text("Takaslık")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ThemeColors.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ThemeColors.primary.opacity(0.15))
                .cornerRadius(12)
            }
            
            Spacer()
            
            bookStatusBadge(status: book.status)
        }
    }
    
    private func bookStatusBadge(status: String) -> some View {
        let statusText = status == "available" ? "Mevcut" :
                       status == "reserved" ? "Rezerve" :
                       "Satıldı/Takas Edildi"
        
        let statusColor = status == "available" ? ThemeColors.success :
                        status == "reserved" ? ThemeColors.warning :
                        ThemeColors.error
        
        return HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(statusColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func ownerInfoView(book: Book) -> some View {
        NavigationLink(destination: UserProfileView(userId: book.ownerId)) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sahibi")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ThemeColors.primaryText)
                        
                        Text(book.ownerDisplayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ThemeColors.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ThemeColors.primary)
                        .padding(8)
                        .background(ThemeColors.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if let location = book.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ThemeColors.tertiaryText)
                        
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundColor(ThemeColors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(ThemeColors.secondaryBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func actionButtonsView(book: Book) -> some View {
        VStack(spacing: 16) {
            // Eğer kitap takaslıksa
            if book.isForTrade {
                Button(action: { showingTradeOfferSheet = true }) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Takas Teklifi Gönder")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: ThemeColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            
            Button(action: { showingMessageSheet = true }) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Satıcıya Mesaj Gönder")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            book.isForTrade ? Color.green : ThemeColors.info,
                            book.isForTrade ? Color.green.opacity(0.8) : ThemeColors.info.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: (book.isForTrade ? Color.green : ThemeColors.info).opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    private var notFoundView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(ThemeColors.tertiaryText)
                .opacity(0.7)
            
            Text("Kitap bulunamadı")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ThemeColors.primaryText)
            
            Text("Bu kitap silinmiş veya mevcut değil")
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Geri Dön")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: ThemeColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
        .background(ThemeColors.background)
    }
    
    private func loadBook() {
        isLoading = true
        
        bookService.fetchBookById(id: bookId) { fetchedBook in
            isLoading = false
            
            if let fetchedBook = fetchedBook {
                self.book = fetchedBook
                
                // Kitap sahibi olup olmadığını kontrol et
                if let userId = authService.user?.id {
                    isOwnerOfBook = fetchedBook.ownerId == userId
                }
            } else {
                errorMessage = "Kitap yüklenirken bir hata oluştu."
            }
        }
    }
    
    private func updateBookStatus(_ newStatus: String) {
        guard let book = book else { return }
        
        bookService.updateBookStatus(bookId: bookId, status: newStatus) { success in
            if success {
                self.book?.status = newStatus
            } else {
                errorMessage = "Kitap durumu güncellenirken bir hata oluştu."
            }
        }
    }
    
    private func deleteBook() {
        isLoading = true
        
        bookService.deleteBook(bookId: bookId) { success in
            isLoading = false
            
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Kitap silinirken bir hata oluştu."
            }
        }
    }
}

struct UserProfileView: View {
    let userId: String
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var ratingService: RatingService
    
    @State private var userBooks: [Book] = []
    @State private var userRatings: [Rating] = []
    @State private var averageRating: Double = 0
    @State private var isLoadingBooks = false
    @State private var isLoadingRatings = false
    @State private var userName: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Kullanıcı bilgileri
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Kullanıcı puanı
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating) + (averageRating.truncatingRemainder(dividingBy: 1) >= 0.5 && star == Int(averageRating) + 1 ? 1 : 0) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(String(format: "%.1f", averageRating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("(\(userRatings.count) değerlendirme)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink(destination: UserRatingsView(userId: userId)) {
                        Text("Tüm Değerlendirmeleri Gör")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Kullanıcının kitapları
                VStack(alignment: .leading) {
                    Text("\(userName)'nin Kitapları")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoadingBooks {
                        ProgressView("Kitaplar yükleniyor...")
                            .padding()
                    } else if userBooks.isEmpty {
                        Text("Bu kullanıcının henüz kitabı bulunmuyor.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(userBooks) { book in
                                    NavigationLink(destination: BookDetailView(bookId: book.id ?? "")) {
                                        VStack(alignment: .leading) {
                                            if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        Rectangle()
                                                            .foregroundColor(.gray.opacity(0.3))
                                                            .frame(width: 120, height: 180)
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 120, height: 180)
                                                            .clipped()
                                                    case .failure:
                                                        Image(systemName: "book.fill")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 120, height: 180)
                                                            .foregroundColor(.gray)
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                                .cornerRadius(8)
                                            } else {
                                                Image(systemName: "book.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 120, height: 180)
                                                    .foregroundColor(.gray)
                                                    .cornerRadius(8)
                                            }
                                            
                                            Text(book.title)
                                                .font(.subheadline)
                                                .lineLimit(2)
                                                .frame(width: 120)
                                            
                                            Text(book.author)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .frame(width: 120)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Kullanıcı Profili")
        .onAppear {
            loadUserBooks()
            loadUserRatings()
        }
    }
    
    private func loadUserBooks() {
        isLoadingBooks = true
        bookService.fetchUserBooks(userId: userId)
        
        // Kitaplar yüklendikten sonra userBooks property'sine atanacak
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.userBooks = self.bookService.userBooks
            if let firstBook = self.userBooks.first {
                self.userName = firstBook.ownerDisplayName
            }
            self.isLoadingBooks = false
        }
    }
    
    private func loadUserRatings() {
        isLoadingRatings = true
        ratingService.fetchUserRatings(userId: userId)
        
        // Değerlendirmeler yüklendikten sonra gerekli işlemleri yapacağız
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.userRatings = self.ratingService.receivedRatings
            if !self.userRatings.isEmpty {
                let total = self.userRatings.reduce(0) { $0 + $1.rating }
                self.averageRating = Double(total) / Double(self.userRatings.count)
            }
            self.isLoadingRatings = false
        }
    }
}