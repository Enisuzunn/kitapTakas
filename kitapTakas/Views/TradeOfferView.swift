import SwiftUI

struct TradeOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var tradeService: TradeService
    
    let requestedBook: Book
    
    @State private var userBooks: [Book] = []
    @State private var selectedBookId: String?
    @State private var message: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    contentView
                }
            }
            .navigationBarTitle("Takas Teklifi", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(ThemeColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text("İptal")
                    .foregroundColor(ThemeColors.accent)
                    .fontWeight(.medium)
            })
            .onAppear {
                loadUserBooks()
            }
            .disabled(isLoading)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Tamam")) {
                        if alertTitle == "Başarılı" {
                            dismiss()
                        }
                    }
                )
            }
        }
        .accentColor(ThemeColors.primary)
    }
    
    // Ana içeriği ayrı bir hesaplanmış özellik olarak çıkarıyorum
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Takas Teklifi Oluştur")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ThemeColors.primaryText)
                .padding(.horizontal)
            
            requestedBookView
            
            Divider()
                .background(ThemeColors.tertiaryText.opacity(0.3))
                .padding(.horizontal)
            
            // Kullanıcının kendi kitapları
            userBooksSection
            
            Divider()
                .background(ThemeColors.tertiaryText.opacity(0.3))
                .padding(.horizontal)
            
            // Mesaj alanı
            messageSection
            
            // Gönder buton
            sendButton
        }
        .padding(.vertical)
    }
    
    // İstenen kitap görünümü
    private var requestedBookView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İstenen Kitap:")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
                .padding(.horizontal, 2)
            
            HStack(spacing: 15) {
                bookImageView
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(requestedBook.title)
                        .font(.headline)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(requestedBook.author)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(ThemeColors.tertiaryText)
                        Text("Kitap Sahibi: \(requestedBook.ownerDisplayName)")
                            .font(.caption)
                            .foregroundColor(ThemeColors.tertiaryText)
                    }
                }
            }
            .padding()
            .background(ThemeColors.cardBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.3), ThemeColors.accent.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal)
    }
    
    // Kitap resmi görünümü
    private var bookImageView: some View {
        Group {
            if let firstImage = requestedBook.imageURLs.first, let url = URL(string: firstImage) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 120)
                        .cornerRadius(10)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(ThemeColors.cardBackground.opacity(0.5))
                        .frame(width: 80, height: 120)
                        .cornerRadius(10)
                        .overlay(
                            ProgressView()
                                .tint(ThemeColors.accent)
                        )
                }
            } else {
                Rectangle()
                    .foregroundColor(ThemeColors.cardBackground.opacity(0.5))
                    .frame(width: 80, height: 120)
                    .cornerRadius(10)
            }
        }
    }
    
    // Kullanıcı kitapları bölümü
    private var userBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teklif Edeceğiniz Kitabı Seçin:")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
                .padding(.horizontal)
            
            if isLoading {
                loadingView
            } else if userBooks.isEmpty {
                emptyBooksView
            } else {
                userBooksList
            }
        }
    }
    
    // Yükleme göstergesi
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView("Kitaplar yükleniyor...")
                .padding()
                .foregroundColor(ThemeColors.secondaryText)
                .tint(ThemeColors.accent)
            Spacer()
        }
    }
    
    // Boş kitaplar görünümü
    private var emptyBooksView: some View {
        VStack(spacing: 15) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 40))
                .foregroundColor(ThemeColors.tertiaryText)
            
            Text("Takasa sunabileceğiniz bir kitabınız yok. Önce kitap ekleyin.")
                .foregroundColor(ThemeColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // Kullanıcı kitapları listesi
    private var userBooksList: some View {
        ForEach(userBooks) { book in
            bookItemView(book)
        }
    }
    
    // Tek bir kitap öğesi
    private func bookItemView(_ book: Book) -> some View {
        Button(action: {
            withAnimation {
                selectedBookId = book.id
            }
        }) {
            HStack(spacing: 15) {
                bookThumbnail(for: book)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                if selectedBookId == book.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ThemeColors.success)
                        .font(.title3)
                }
            }
            .padding()
            .background(selectedBookId == book.id ? 
                ThemeColors.primary.opacity(0.15) : 
                ThemeColors.cardBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedBookId == book.id ?
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.success.opacity(0.5), ThemeColors.success.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.2), ThemeColors.accent.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: selectedBookId == book.id ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // Kitap küçük resmi
    private func bookThumbnail(for book: Book) -> some View {
        Group {
            if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(ThemeColors.cardBackground.opacity(0.5))
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .tint(ThemeColors.accent)
                        )
                }
            } else {
                Rectangle()
                    .foregroundColor(ThemeColors.cardBackground.opacity(0.5))
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
            }
        }
    }
    
    // Mesaj bölümü
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Takas teklifiniz için mesaj (opsiyonel):")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
                .padding(.horizontal)
            
            TextEditor(text: $message)
                .frame(minHeight: 100)
                .padding(10)
                .foregroundColor(ThemeColors.primaryText)
                .background(ThemeColors.secondaryBackground.opacity(0.6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [ThemeColors.primary.opacity(0.4), ThemeColors.accent.opacity(0.4)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .padding(.horizontal)
        }
    }
    
    // Gönder butonu
    private var sendButton: some View {
        Button(action: sendTradeOffer) {
            HStack {
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                    Text("Takas Teklifi Gönder")
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                selectedBookId == nil ?
                LinearGradient(
                    gradient: Gradient(colors: [ThemeColors.tertiaryText.opacity(0.5), ThemeColors.tertiaryText.opacity(0.5)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: selectedBookId == nil ? Color.clear : ThemeColors.primary.opacity(0.4), radius: 5, x: 0, y: 3)
            .padding()
        }
        .disabled(selectedBookId == nil || isLoading)
    }
    
    private func loadUserBooks() {
        guard let userId = authService.user?.id else {
            alertTitle = "Hata"
            alertMessage = "Kullanıcı bilgisi alınamadı."
            showAlert = true
            return
        }
        
        isLoading = true
        
        bookService.fetchUserBooks(userId: userId)
        
        // Kullanıcının kendi kitaplarını yükle ve bu kitaptan farklı olanları görüntüle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            
            // Sadece takas için uygun kitapları göster
            self.userBooks = bookService.userBooks.filter { book in
                book.isForTrade && 
                book.id != requestedBook.id && 
                book.status == "available"
            }
        }
    }
    
    private func sendTradeOffer() {
        guard let userId = authService.user?.id, let userName = authService.user?.name else {
            alertTitle = "Hata"
            alertMessage = "Kullanıcı bilgisi alınamadı."
            showAlert = true
            return
        }
        
        guard let offeredBookId = selectedBookId else {
            alertTitle = "Hata"
            alertMessage = "Lütfen takas için bir kitap seçin."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let now = Date()
        let tradeOffer = TradeOffer(
            offeredBookId: offeredBookId,
            requestedBookId: requestedBook.id ?? "",
            offererId: userId,
            receiverId: requestedBook.ownerId,
            status: "pending",
            message: message,
            createdAt: now,
            updatedAt: now
        )
        
        tradeService.createTradeOffer(offer: tradeOffer) { success, _ in
            isLoading = false
            
            if success {
                alertTitle = "Başarılı"
                alertMessage = "Takas teklifiniz gönderildi."
            } else {
                alertTitle = "Hata"
                alertMessage = "Takas teklifi gönderilirken bir hata oluştu."
            }
            
            showAlert = true
        }
    }
} 