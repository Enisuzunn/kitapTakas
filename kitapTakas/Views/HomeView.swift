import SwiftUI

struct HomeView: View {
    @StateObject private var bookService = BookService()
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedCategory: String? = nil
    @State private var isFilterActive = false
    @State private var showTradeOnly = false
    @State private var showSaleOnly = false
    
    private let categories = ["Roman", "Bilim", "Kişisel Gelişim", "Tarih", "Felsefe", "Çocuk", "Diğer"]
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Başlık
                        HStack {
                            Text("Kitap Dünyası")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ThemeColors.primaryText)
                            
                            Spacer()
                            
                    Button(action: {
                                showTradeOnly.toggle()
                                showSaleOnly = false
                                bookService.filterBooks(
                                    searchText: "",
                                    category: selectedCategory,
                                    tradeOnly: showTradeOnly,
                                    saleOnly: false
                                )
                    }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(ThemeColors.primary)
                    }
                }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Öne çıkan kitaplar bölümü
                        if !bookService.isLoading && !bookService.books.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Öne Çıkan Kitaplar")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(ThemeColors.primaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(bookService.books.prefix(5))) { book in
                                            NavigationLink(destination: BookDetailView(bookId: book.id ?? "")) {
                                                FeaturedBookCard(book: book)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // Kategori seçim alanı
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                                // Tüm Kategoriler butonu
                                Button(action: {
                                    selectedCategory = nil
                                    bookService.filterBooks(
                                        searchText: "",
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
                                            searchText: "",
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
                            .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
                        .background(ThemeColors.background)
            
                        // Ana içerik
            if bookService.isLoading {
                            loadingView
                        } else if bookService.filteredBooks.isEmpty {
                            emptyStateView
            } else {
                    LazyVStack(spacing: 16) {
                                ForEach(bookService.filteredBooks) { book in
                            NavigationLink(destination: BookDetailView(bookId: book.id ?? "")) {
                                BookCard(book: book)
                                            .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(CardButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarHidden(true)
        .onAppear {
            if bookService.books.isEmpty {
                bookService.fetchAllBooks()
            }
        }
        .refreshable {
            bookService.fetchAllBooks()
        }
    }
}

    // MARK: - Alt Görünümler
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
            
            Text("Kitaplar yükleniyor...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.primaryText)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        Spacer()
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(ThemeColors.tertiaryText)
                .opacity(0.8)
            
            if selectedCategory != nil || showTradeOnly || showSaleOnly {
                Text("Aranan kriterlere uygun kitap bulunamadı")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ThemeColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    selectedCategory = nil
                    showTradeOnly = false
                    showSaleOnly = false
                    bookService.filterBooks(
                        searchText: "",
                        category: nil,
                        tradeOnly: false,
                        saleOnly: false
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
                .padding(.top, 12)
            } else {
                Text("Henüz kitap eklenmemiş")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ThemeColors.secondaryText)
            }
        }
        .padding()
        Spacer()
    }
}

// Öne çıkan kitaplar için yeni kart yapısı
struct FeaturedBookCard: View {
    let book: Book
    @State private var imageLoaded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kitap resmi
            ZStack {
                if !imageLoaded {
                    Rectangle()
                        .fill(ThemeColors.secondaryBackground)
                        .frame(width: 160, height: 220)
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
                            Color.clear
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 220)
                                .clipped()
                                .cornerRadius(12)
                                .onAppear {
                                    imageLoaded = true
                                }
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(40)
                                .frame(width: 160, height: 220)
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
                        .padding(40)
                        .frame(width: 160, height: 220)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ThemeColors.primaryText)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.secondaryText)
                    .lineLimit(1)
                
                HStack {
                    if book.isForTrade {
                        Text("Takaslık")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ThemeColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ThemeColors.primary.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 160)
        .padding(.bottom, 8)
        .background(ThemeColors.background)
        .cornerRadius(12)
        .shadow(color: ThemeColors.primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Kitap resmi
                bookImage
                
                VStack(alignment: .leading, spacing: 8) {
                    // Kitap başlığı ve yazarı
                    Text(book.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeColors.primaryText)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ThemeColors.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Etiketler
                    HStack(alignment: .center, spacing: 8) {
                        if book.isForTrade {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(ThemeColors.primary)
                                
                                Text("Takaslık")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ThemeColors.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ThemeColors.primary.opacity(0.15))
                            .cornerRadius(8)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.system(size: 11))
                                .foregroundColor(ThemeColors.tertiaryText)
                            
                            Text(book.category)
                                .font(.system(size: 12))
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ThemeColors.secondaryBackground)
                        .cornerRadius(8)
                        }
                    }
            }
            
            // Kitap açıklaması
            Text(book.description)
                .font(.system(size: 14))
                .lineLimit(2)
                .foregroundColor(ThemeColors.secondaryText)
                .padding(.top, 4)
            
            // Alt bilgi kısmı
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.tertiaryText)
                        
                    Text(book.ownerDisplayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                // Kitap durumu
                Text(book.status == "available" ? "Mevcut" : 
                    book.status == "reserved" ? "Rezerve" : "Takas Edildi")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundColor(
                        book.status == "available" ? ThemeColors.success :
                        book.status == "reserved" ? ThemeColors.warning :
                        ThemeColors.error
                    )
                    .background(
                        book.status == "available" ? ThemeColors.success.opacity(0.15) :
                        book.status == "reserved" ? ThemeColors.warning.opacity(0.15) :
                        ThemeColors.error.opacity(0.15)
                    )
                    .cornerRadius(12)
            }
        }
        .padding(18)
        .background(ThemeColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: ThemeColors.primary.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Alt Görünümler
    
    @ViewBuilder
    private var bookImage: some View {
        ZStack {
            // Temel arka plan
            Rectangle()
                .fill(ThemeColors.secondaryBackground)
                .frame(width: 90, height: 120)
                .cornerRadius(12)
            
            if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.primary))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 120)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        VStack(spacing: 6) {
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(ThemeColors.tertiaryText)
                            
                            Text("Görüntü\nyüklenemedi")
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                                .foregroundColor(ThemeColors.tertiaryText)
                        }
                        .padding()
                        .frame(width: 90, height: 120)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
        .padding()
                    .foregroundColor(ThemeColors.tertiaryText)
            }
        }
    }
}

// Özel tıklama animasyonu için ButtonStyle
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(BookService())
            .environmentObject(AuthService.shared)
            .environmentObject(TradeService())
            .environmentObject(ChatService())
            .environmentObject(RatingService())
    }
} 