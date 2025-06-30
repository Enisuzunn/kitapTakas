import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var ratingService: RatingService
    
    @State private var showingSettings = false
    @State private var averageRating: Double = 0
    @State private var totalRatings: Int = 0
    @State private var isLoadingRatings = false
    @State private var userRatings: [Rating] = []
    
    var body: some View {
        ZStack {
            ThemeColors.background
                .ignoresSafeArea()
            
        ScrollView {
            VStack(spacing: 20) {
                // Profil bilgileri
                    VStack(spacing: 15) {
                        if let profileImageUrl = authService.user?.profileImageUrl, let url = URL(string: profileImageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                                        .foregroundColor(ThemeColors.primaryText)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                        .overlay(Circle().stroke(ThemeColors.primary, lineWidth: 2))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                        .foregroundColor(ThemeColors.primary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                                .foregroundColor(ThemeColors.primary)
                    }
                    
                        Text(authService.user?.name ?? "İsimsiz Kullanıcı")
                        .font(.title2)
                        .fontWeight(.bold)
                            .foregroundColor(ThemeColors.primaryText)
                    
                    Text(authService.user?.email ?? "")
                        .font(.subheadline)
                            .foregroundColor(ThemeColors.secondaryText)
                    
                    // Kullanıcı puanı
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating) + (averageRating.truncatingRemainder(dividingBy: 1) >= 0.5 && star == Int(averageRating) + 1 ? 1 : 0) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(String(format: "%.1f", averageRating))
                            .font(.subheadline)
                                .foregroundColor(ThemeColors.secondaryText)
                        
                        Text("(\(totalRatings) değerlendirme)")
                            .font(.caption)
                                .foregroundColor(ThemeColors.tertiaryText)
                    }
                    .padding(.top, 4)
                    
                    NavigationLink(destination: UserRatingsView(userId: authService.user?.id ?? "")) {
                        Text("Değerlendirmeleri Gör")
                            .font(.caption)
                                .foregroundColor(ThemeColors.primary)
                    }
                    
                    // İstatistikler
                    HStack {
                        VStack {
                            Text("\(bookService.userBooks.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                    .foregroundColor(ThemeColors.primaryText)
                            
                            Text("Kitaplar")
                                .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                                .background(ThemeColors.secondaryText.opacity(0.3))
                        
                        VStack {
                            Text("\(bookService.userBooks.filter { $0.status != "available" }.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                    .foregroundColor(ThemeColors.primaryText)
                            
                            Text("Takas/Satış")
                                .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                        .background(ThemeColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding()
                    .background(ThemeColors.secondaryBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Kitaplarım
                    VStack(spacing: 15) {
                HStack {
                    Text("Kitaplarım")
                        .font(.headline)
                                .foregroundColor(ThemeColors.primaryText)
                    
                    Spacer()
                    
                    NavigationLink(destination: AddBookView()) {
                        Label("Yeni Ekle", systemImage: "plus")
                            .font(.subheadline)
                                    .foregroundColor(ThemeColors.primary)
                    }
                }
                .padding(.horizontal)
                
                if bookService.isLoading {
                    ProgressView("Kitaplar yükleniyor...")
                        .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(ThemeColors.primaryText)
                        .padding()
                } else if bookService.userBooks.isEmpty {
                            VStack(spacing: 15) {
                        Image(systemName: "book.closed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                                    .foregroundColor(ThemeColors.tertiaryText)
                        
                        Text("Henüz kitap eklemediniz")
                            .font(.subheadline)
                                    .foregroundColor(ThemeColors.secondaryText)
                        
                        NavigationLink(destination: AddBookView()) {
                            Text("Kitap Ekle")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                        .background(ThemeColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                            .padding(.vertical, 20)
                } else {
                    VStack(spacing: 16) {
                        ForEach(bookService.userBooks) { book in
                                    ProfileUserBookCard(book: book)
                                .padding(.horizontal)
                        }
                            }
                    }
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    Label("Ayarlar", systemImage: "gear")
                            .foregroundColor(ThemeColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                            .background(ThemeColors.secondaryBackground)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
            }
            .padding(.vertical)
            }
        }
        .navigationTitle("Profilim")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            configureNavigationBar()
            if let userId = authService.user?.id {
                bookService.fetchUserBooks(userId: userId)
                loadUserRatings(userId: userId)
            }
        }
    }
    
    private func loadUserRatings(userId: String) {
        isLoadingRatings = true
        
        Task {
            let ratings = await ratingService.fetchUserRatingsAsync(userId: userId)
            self.userRatings = ratings
            
            if !self.userRatings.isEmpty {
                let total = self.userRatings.reduce(0) { $0 + $1.rating }
                self.averageRating = Double(total) / Double(self.userRatings.count)
                self.totalRatings = self.userRatings.count
            }
            
            self.isLoadingRatings = false
        }
    }
}

struct ProfileUserBookCard: View {
    @EnvironmentObject var bookService: BookService
    let book: Book
    
    @State private var showingOptions = false
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Kitap görseli
                if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 90)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 90)
                                .foregroundColor(ThemeColors.tertiaryText)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 90)
                        .foregroundColor(ThemeColors.tertiaryText)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    HStack {
                        Text(book.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ThemeColors.primary.opacity(0.1))
                            .foregroundColor(ThemeColors.primary)
                            .cornerRadius(4)
                        
                        Text(book.condition)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    // Satış ve takas etiketleri
                    HStack {
                        if book.isForSale {
                            Label(
                                book.price != nil ? "\(book.price!) TL" : "Satılık",
                                systemImage: "tag"
                            )
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                        }
                        
                        if book.isForTrade {
                            Label(
                                "Takaslık",
                                systemImage: "arrow.left.arrow.right"
                            )
                            .font(.caption)
                            .foregroundColor(ThemeColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColors.primary.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // Durum göstergesi ve menü
                VStack {
                    Menu {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            if let bookId = book.id {
                                bookService.updateBookStatus(
                                    bookId: bookId, 
                                    status: book.status == "available" ? "reserved" : "available"
                                )
                                // İstek tamamlandıktan sonra kullanıcı kitaplarını yenile
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    if let userId = bookService.currentUserId {
                                        bookService.fetchUserBooks(userId: userId)
                                    }
                                }
                            }
                        }) {
                            Label(
                                book.status == "available" ? "Rezerve Et" : "Mevcut Yap",
                                systemImage: book.status == "available" ? "lock" : "lock.open"
                            )
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(8)
                            .background(ThemeColors.secondaryBackground)
                            .foregroundColor(ThemeColors.primaryText)
                            .cornerRadius(8)
                    }
                    
                    Text(book.status == "available" ? "Mevcut" : 
                         book.status == "reserved" ? "Rezerve" : "Takas Edildi")
                        .font(.caption2)
                        .foregroundColor(
                            book.status == "available" ? .green :
                            book.status == "reserved" ? .orange : .red
                        )
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(10)
        .sheet(isPresented: $showingEditView) {
            if let bookId = book.id {
                NavigationView {
                    AddBookView(editMode: true, bookToEdit: book)
                        .navigationTitle("Kitabı Düzenle")
                }
            }
        }
        .alert("Kitabı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                if let id = book.id {
                    bookService.deleteBook(bookId: id)
                    // İstek tamamlandıktan sonra kullanıcı kitaplarını yenile
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if let userId = bookService.currentUserId {
                            bookService.fetchUserBooks(userId: userId)
                        }
                    }
                }
            }
        } message: {
            Text("Bu kitabı silmek istediğinize emin misiniz?")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Profil bilgileri
                    VStack(spacing: 16) {
                        if let profileImageUrl = authService.user?.profileImageUrl, let url = URL(string: profileImageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(ThemeColors.primary, lineWidth: 2))
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(ThemeColors.primary)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(ThemeColors.primary)
                        }
                        
                        Text(authService.user?.name ?? "Kullanıcı")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(ThemeColors.primaryText)
                        
                        Text(authService.user?.email ?? "")
                            .font(.system(size: 16))
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    .padding(.vertical, 16)
                    
                    // Ayarlar Bölümü
                    VStack(spacing: 0) {
                        // Hesap Bölümü
                        sectionHeader(title: "Hesap")
                        
                        settingsButton(
                            icon: "person.crop.circle",
                            title: "Profil Bilgileri",
                            description: "Kişisel bilgilerinizi güncelleyin",
                            action: {}
                        )
                        
                        settingsButton(
                            icon: "bell",
                            title: "Bildirimler",
                            description: "Bildirim tercihlerinizi yönetin",
                            action: {}
                        )
                        
                        settingsButton(
                            icon: "arrow.right.square",
                            title: "Çıkış Yap",
                            description: "Hesabınızdan güvenli çıkış yapın",
                            color: ThemeColors.error,
                            showDivider: false,
                            action: {
                        authService.signOut()
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                        
                        // Uygulama Hakkında Bölümü
                        sectionHeader(title: "Uygulama Hakkında")
                        
                        settingsButton(
                            icon: "info.circle",
                            title: "Versiyon",
                            description: "1.0.0",
                            showArrow: false,
                            action: {}
                        )
                        
                        settingsButton(
                            icon: "lock.shield",
                            title: "Gizlilik Politikası",
                            description: "Kişisel verilerinizin nasıl kullanıldığı",
                            destination: AnyView(privacyPolicyView)
                        )
                        
                        settingsButton(
                            icon: "doc.text",
                            title: "Kullanım Koşulları",
                            description: "Uygulama kullanım şartları",
                            showDivider: false,
                            destination: AnyView(termsAndConditionsView)
                        )
                        
                        // Diğer Bölüm
                        sectionHeader(title: "Diğer")
                        
                        settingsButton(
                            icon: "star",
                            title: "Uygulamayı Değerlendir",
                            description: "App Store'da puan verin",
                            showDivider: false,
                            action: {}
                        )
                    }
                    .background(ThemeColors.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("Kitap Takas © 2024")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.tertiaryText)
                        .padding(.bottom, 8)
                }
                .padding(.top)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(ThemeColors.primary)
                    .font(.system(size: 16, weight: .medium))
                }
            }
                    }
                }
                
    private func sectionHeader(title: String) -> some View {
                    HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ThemeColors.tertiaryText)
                .padding(.leading, 16)
            
                        Spacer()
        }
        .padding(.vertical, 12)
        .padding(.top, 4)
        .background(ThemeColors.cardBackground)
    }
    
    private func settingsButton(
        icon: String,
        title: String,
        description: String,
        color: Color = ThemeColors.primary,
        showArrow: Bool = true,
        showDivider: Bool = true,
        destination: AnyView? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        VStack(spacing: 0) {
            Group {
                if let destination = destination {
                    NavigationLink(destination: destination) {
                        buttonContent(icon: icon, title: title, description: description, color: color, showArrow: showArrow)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: action) {
                        buttonContent(icon: icon, title: title, description: description, color: color, showArrow: showArrow)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            if showDivider {
                Divider()
                    .background(ThemeColors.tertiaryText.opacity(0.2))
                    .padding(.leading, 56)
            }
        }
    }
    
    private func buttonContent(
        icon: String,
        title: String,
        description: String,
        color: Color,
        showArrow: Bool
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ThemeColors.primaryText)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(ThemeColors.tertiaryText)
                    }
                    
            Spacer()
            
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ThemeColors.tertiaryText)
            }
        }
    }
    
    private var privacyPolicyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Gizlilik Politikası")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ThemeColors.primaryText)
                
                Text("Son güncelleme: 14 Mayıs 2024")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.tertiaryText)
                
                Text("Bu gizlilik politikası, Kitap Takas uygulamasını kullanırken toplanan bilgileri ve bu bilgilerin nasıl kullanıldığını açıklar.")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.vertical, 8)
                
                // Gizlilik politikası içeriği buraya eklenebilir
                Text("Topladığımız Bilgiler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.top, 8)
                
                Text("Uygulamamızı kullanırken, sizden belirli kişisel bilgileri topluyoruz. Bu bilgiler, uygulamayı kullanmanız için gerekli olan hesap bilgilerinizi, kitap takası için gerekli iletişim bilgilerinizi ve konum bilgilerinizi içerebilir.")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.vertical, 4)
                
                // Daha fazla içerik...
            }
            .padding()
        }
        .background(ThemeColors.background.ignoresSafeArea())
        .navigationTitle("Gizlilik Politikası")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var termsAndConditionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kullanım Koşulları")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ThemeColors.primaryText)
                
                Text("Son güncelleme: 14 Mayıs 2024")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.tertiaryText)
                
                Text("Kitap Takas uygulamasını kullanarak, aşağıdaki koşulları kabul etmiş olursunuz:")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.vertical, 8)
                
                // Kullanım koşulları içeriği buraya eklenebilir
                Text("Hesap Oluşturma")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.top, 8)
                
                Text("Uygulamamızı kullanmak için bir hesap oluşturmanız gerekir. Hesap oluştururken, doğru ve güncel bilgiler sağlamakla yükümlüsünüz. Hesabınızın güvenliğini korumak sizin sorumluluğunuzdadır.")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeColors.primaryText)
                    .padding(.vertical, 4)
                
                // Daha fazla içerik...
            }
            .padding()
        }
        .background(ThemeColors.background.ignoresSafeArea())
        .navigationTitle("Kullanım Koşulları")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthService())
            .environmentObject(BookService())
            .environmentObject(RatingService())
    }
} 