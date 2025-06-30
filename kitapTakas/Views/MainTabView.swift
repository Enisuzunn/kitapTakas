import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var tradeService: TradeService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var ratingService: RatingService
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
                    .environmentObject(authService)
                    .environmentObject(bookService)
            }
            .tabItem {
                Label("Ana Sayfa", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                MainExploreView()
            }
                .tabItem {
                Label("Keşfet", systemImage: "magnifyingglass")
                }
            .tag(1)
            
            NavigationView {
                AddBookView()
                    .environmentObject(authService)
                    .environmentObject(bookService)
            }
            .tabItem {
                Label("Kitap Ekle", systemImage: "plus.circle.fill")
            }
            .tag(2)
            
            NavigationView {
                TradeOffersView()
                    .environmentObject(authService)
                    .environmentObject(tradeService)
                    .environmentObject(bookService)
            }
            .tabItem {
                ZStack {
                    Label("Takaslar", systemImage: "arrow.triangle.swap")
                    
                    if tradeService.pendingReceivedCount > 0 {
                        ZStack {
                            Circle()
                                .fill(ThemeColors.primary)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(ThemeColors.background, lineWidth: 2)
                                )
                            
                            Text("\(min(tradeService.pendingReceivedCount, 99))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 16, y: -10)
                    }
                }
            }
            .tag(3)
            
            NavigationView {
                MoreView()
                    .environmentObject(authService)
                    .environmentObject(chatService)
            }
            .tabItem {
                Label("Diğer", systemImage: "ellipsis")
            }
            .tag(4)
        }
        .accentColor(ThemeColors.primary)
        .onAppear {
            // Tab bar görünümünü özelleştir
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Arka plan ayarları
            appearance.backgroundColor = UIColor(ThemeColors.background)
            
            // Seçili olmayan tab öğeleri ayarları
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(ThemeColors.tertiaryText)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(ThemeColors.tertiaryText)]
            
            // Seçili tab öğeleri için ayarlar
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(ThemeColors.primary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(ThemeColors.primary)]
            
            // Tab bar gölgesi
            appearance.shadowColor = .clear
            
            // Border yerine üst çizgi
            appearance.shadowImage = UIImage()
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

struct MainHomeView: View {
    var body: some View {
        ZStack {
            ThemeColors.background
                .ignoresSafeArea()
            
            Text("Ana Sayfa")
                .foregroundColor(ThemeColors.primaryText)
        }
        .navigationTitle("Ana Sayfa")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            configureNavigationBar()
        }
    }
}

struct MainExploreView: View {
    @StateObject private var bookService = BookService()
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showTradeOnly = false
    @State private var showSaleOnly = false
    
    private let categories = ["Roman", "Bilim", "Kişisel Gelişim", "Tarih", "Felsefe", "Çocuk", "Diğer"]
    
    var body: some View {
        ZStack {
            ThemeColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Arama alanı
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ThemeColors.tertiaryText)
                    
                    TextField("", text: $searchText)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Kitap veya yazar ara")
                                .foregroundColor(ThemeColors.tertiaryText)
                        }
                        .foregroundColor(ThemeColors.primaryText)
                        .onChange(of: searchText) { _ in
                            bookService.filterBooks(
                                searchText: searchText, 
                                category: selectedCategory,
                                tradeOnly: showTradeOnly,
                                saleOnly: showSaleOnly
                            )
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            bookService.filterBooks(
                                searchText: "", 
                                category: selectedCategory,
                                tradeOnly: showTradeOnly,
                                saleOnly: showSaleOnly
                            )
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ThemeColors.tertiaryText)
                        }
                    }
                }
                .padding()
                .background(ThemeColors.secondaryBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Kategoriler
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedCategory = nil
                            bookService.filterBooks(
                                searchText: searchText,
                                category: nil,
                                tradeOnly: showTradeOnly,
                                saleOnly: showSaleOnly
                            )
                        }) {
                            Text("Tümü")
                                .font(.system(size: 14, weight: selectedCategory == nil ? .semibold : .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? ThemeColors.primary : ThemeColors.secondaryBackground)
                                .foregroundColor(selectedCategory == nil ? .white : ThemeColors.secondaryText)
                                .cornerRadius(20)
                                .shadow(color: selectedCategory == nil ? ThemeColors.primary.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                bookService.filterBooks(
                                    searchText: searchText,
                                    category: category,
                                    tradeOnly: showTradeOnly,
                                    saleOnly: showSaleOnly
                                )
                            }) {
                                Text(category)
                                    .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? ThemeColors.primary : ThemeColors.secondaryBackground)
                                    .foregroundColor(selectedCategory == category ? .white : ThemeColors.secondaryText)
                                    .cornerRadius(20)
                                    .shadow(color: selectedCategory == category ? ThemeColors.primary.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                
                // Ana içerik
                if bookService.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
                    Spacer()
                } else if bookService.filteredBooks.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(ThemeColors.tertiaryText)
                            .opacity(0.8)
                        
                        Text("Arama sonucu bulunamadı")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ThemeColors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        if !searchText.isEmpty || selectedCategory != nil {
                            Button(action: {
                                searchText = ""
                                selectedCategory = nil
                                bookService.filterBooks(
                                    searchText: "",
                                    category: nil,
                                    tradeOnly: showTradeOnly,
                                    saleOnly: showSaleOnly
                                )
                            }) {
                                Text("Filtreleri Temizle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(ThemeColors.primary)
                                    .cornerRadius(10)
                                    .shadow(color: ThemeColors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(bookService.filteredBooks) { book in
                                NavigationLink(destination: BookDetailView(bookId: book.id ?? "")) {
                                    ExploreBookCard(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Keşfet")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            configureNavigationBar()
            if bookService.books.isEmpty {
                bookService.fetchAllBooks()
            }
        }
        .refreshable {
            bookService.fetchAllBooks()
        }
    }
}

struct ExploreBookCard: View {
    let book: Book
    @State private var isPressed: Bool = false
    @State private var imageLoaded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kitap resmi
            ZStack {
                // Yükleme durumu arka planı
                if !imageLoaded {
                    Rectangle()
                        .fill(ThemeColors.secondaryBackground)
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
                        )
                }
                
                if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.clear // Zaten yükleniyor göstergesi koyduğumuz için boş bırakıyoruz
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                                .onAppear {
                                    imageLoaded = true
                                }
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 160)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(ThemeColors.tertiaryText)
                                .background(ThemeColors.secondaryBackground)
                                .cornerRadius(12)
                                .onAppear {
                                    print("Failed to load image: \(url)")
                                    imageLoaded = true
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(ThemeColors.tertiaryText)
                        .background(ThemeColors.secondaryBackground)
                        .cornerRadius(12)
                        .onAppear {
                            imageLoaded = true
                        }
                }
            }
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ThemeColors.primaryText)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundColor(ThemeColors.secondaryText)
                    .lineLimit(1)
                
                HStack {
                    if book.isForTrade {
                        Text("Takaslık")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ThemeColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColors.primary.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 8)
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isPressed ? 0.1 : 0.15), radius: isPressed ? 3 : 5, x: 0, y: isPressed ? 1 : 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}

struct MainChatListView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        MessagesView()
            .environmentObject(authService)
            .environmentObject(chatService)
            .onAppear {
                if let userId = authService.user?.id {
                    chatService.getUserConversations(userId: userId)
                }
            }
    }
}

// NavigationBar görünümünü özelleştiren fonksiyon
func configureNavigationBar() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()
    
    // Arka plan rengi
    appearance.backgroundColor = UIColor(ThemeColors.background)
    
    // Başlık rengi
    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor(ThemeColors.primaryText),
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor(ThemeColors.primaryText),
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]
    
    // Button görünümü
    let buttonAppearance = UIBarButtonItemAppearance()
    buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(ThemeColors.primary)]
    appearance.buttonAppearance = buttonAppearance
    
    // Gölge kaldırma
    appearance.shadowColor = .clear
    
    // Uygulamaya atama
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
        .environmentObject(BookService())
        .environmentObject(TradeService())
        .environmentObject(ChatService())
        .environmentObject(RatingService())
} 