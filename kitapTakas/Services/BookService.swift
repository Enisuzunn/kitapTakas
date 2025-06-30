import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class BookService: ObservableObject {
    @Published var books: [Book] = []
    @Published var userBooks: [Book] = []
    @Published var recentBooks: [Book] = []
    @Published var categoryBooks: [Book] = []
    @Published var filteredBooks: [Book] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    // Tüm kitapları getir
    func fetchAllBooks() {
        isLoading = true
        db.collection("books")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Kitaplar yüklenemedi"
                    return
                }
                
                self.books = documents.compactMap { document in
                    try? document.data(as: Book.self)
                }
                
                // Başlangıçta filtrelenmiş kitapları da tüm kitaplar olarak ayarla
                self.filteredBooks = self.books
            }
    }
    
    // Kitapları filtrele
    func filterBooks(searchText: String, category: String?, tradeOnly: Bool, saleOnly: Bool) {
        var result = books
        
        // Arama metni filtresi
        if !searchText.isEmpty {
            result = result.filter { 
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.author.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Kategori filtresi
        if let category = category, !category.isEmpty {
            result = result.filter { $0.category == category }
        }
        
        // Takas seçeneği filtresi
        if tradeOnly {
            result = result.filter { $0.isForTrade }
        }
        
        // Satılık seçeneği filtresi
        if saleOnly {
            result = result.filter { $0.isForSale }
        }
        
        // Sonuçları güncelle
        filteredBooks = result
    }
    
    // En son eklenen kitapları getir
    func fetchRecentBooks(limit: Int = 10) {
        isLoading = true
        db.collection("books")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Son eklenen kitaplar yüklenemedi"
                    return
                }
                
                self.recentBooks = documents.compactMap { document in
                    try? document.data(as: Book.self)
                }
            }
    }
    
    // Kategoriye göre kitapları getir
    func fetchBooksByCategory(category: String, limit: Int = 20) {
        isLoading = true
        db.collection("books")
            .whereField("category", isEqualTo: category)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Kategori kitapları yüklenemedi"
                    return
                }
                
                self.categoryBooks = documents.compactMap { document in
                    try? document.data(as: Book.self)
                }
            }
    }
    
    // Kullanıcı kitaplarını getir
    func fetchUserBooks(userId: String) {
        isLoading = true
        db.collection("books")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Kullanıcı kitapları yüklenemedi"
                    return
                }
                
                self.userBooks = documents.compactMap { document in
                    try? document.data(as: Book.self)
                }
            }
    }
    
    // ID'ye göre kitap getir
    func fetchBookById(id: String, completion: @escaping (Book?) -> Void) {
        isLoading = true
        
        db.collection("books").document(id).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            let book = try? snapshot.data(as: Book.self)
            completion(book)
        }
    }
    
    // Kitap ekle
    func addBook(book: Book, imageData: [Data], completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        var bookToAdd = book
        var uploadedURLs: [String] = []
        
        let dispatchGroup = DispatchGroup()
        
        // Görsel yükleme işlemi
        for data in imageData {
            dispatchGroup.enter()
            // Benzersiz bir dosya adı oluştur
            let fileName = "\(UUID().uuidString).jpg"
            let fileRef = storage.child("bookImages/\(fileName)")
            
            // Metadata ayarla
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.cacheControl = "public, max-age=31536000" // 1 yıl önbellek
            
            fileRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    self.errorMessage = "Görsel yükleme hatası: \(error.localizedDescription)"
                    print("Görsel yükleme hatası: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                fileRef.downloadURL { url, error in
                    if let error = error {
                        self.errorMessage = "URL alma hatası: \(error.localizedDescription)"
                        print("URL alma hatası: \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let url = url {
                        let urlString = url.absoluteString
                        uploadedURLs.append(urlString)
                        print("Başarıyla yüklenen görsel: \(urlString)")
                    } else {
                        print("URL alınamadı")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            bookToAdd.imageURLs = uploadedURLs
            bookToAdd.createdAt = Date()
            bookToAdd.updatedAt = Date()
            
            do {
                let docRef = try self.db.collection("books").addDocument(from: bookToAdd)
                print("Kitap başarıyla eklendi: \(docRef.documentID), görsel sayısı: \(uploadedURLs.count)")
                self.isLoading = false
                completion(true, docRef.documentID)
            } catch {
                self.errorMessage = error.localizedDescription
                print("Kitap ekleme hatası: \(error.localizedDescription)")
                self.isLoading = false
                completion(false, nil)
            }
        }
    }
    
    // Kitap güncelleme fonksiyonu
    func updateBook(bookId: String, data: [String: Any], newImageData: [Data]? = nil, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Önce kitap bilgilerini güncelle
        db.collection("books").document(bookId).updateData(data) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            // Eğer yeni bir görsel yoksa işlem tamamlandı
            if newImageData == nil || newImageData?.isEmpty == true {
                self.isLoading = false
                completion(true)
                return
            }
            
            // Kitabı önce getir ve mevcut görselleri al
            self.db.collection("books").document(bookId).getDocument { [weak self] document, error in
                guard let self = self, let document = document, document.exists else {
                    self?.errorMessage = error?.localizedDescription ?? "Kitap bilgileri alınamadı"
                    self?.isLoading = false
                    completion(false)
                    return
                }
                
                do {
                    let book = try document.data(as: Book.self)
                    
                    // Önce yeni görselleri yükle
                    self.uploadBookImages(bookId: bookId, imageData: newImageData!) { success, imageURLs in
                        if success, let imageURLs = imageURLs {
                            // Mevcut görselleri al ve yenileri ile birleştir
                            var updatedImageURLs = book.imageURLs
                            updatedImageURLs.append(contentsOf: imageURLs)
                            
                            // Kitap belgesini güncelle
                            self.db.collection("books").document(bookId).updateData([
                                "imageURLs": updatedImageURLs
                            ]) { error in
                                self.isLoading = false
                                
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    completion(false)
                                } else {
            completion(true)
        }
                            }
                        } else {
                            self.isLoading = false
                            self.errorMessage = "Görsel yüklenirken bir hata oluştu"
                            completion(false)
                        }
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // Görselleri yükleme fonksiyonu (mevcut kodu kullanır)
    private func uploadBookImages(bookId: String, imageData: [Data], completion: @escaping (Bool, [String]?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var imageURLs: [String] = []
        var hasError = false
        
        for (index, data) in imageData.enumerated() {
            dispatchGroup.enter()
            
            let imageRef = storage.child("bookImages/\(bookId)/\(UUID().uuidString).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.cacheControl = "public, max-age=31536000" // 1 yıl cache
            
            imageRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    hasError = true
                    dispatchGroup.leave()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        hasError = true
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                        print("Resim başarıyla yüklendi: \(url.absoluteString)") // Debug için URL kontrolü
                    } else {
                        print("URL alınamadı")
                        hasError = true
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(!hasError, imageURLs)
        }
    }
    
    // Kitabın durumunu güncelle - Overload metodu (completion handler olmadan)
    func updateBookStatus(bookId: String, status: String) {
        isLoading = true
        
        db.collection("books").document(bookId).updateData([
            "status": status,
            "updatedAt": Date()
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Kitabın durumunu güncelle - Orijinal metod (completion handler ile)
    func updateBookStatus(bookId: String, status: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("books").document(bookId).updateData([
            "status": status,
            "updatedAt": Date()
        ]) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    // Kitap sil - Overload metodu (completion handler olmadan)
    func deleteBook(bookId: String) {
        isLoading = true
        
        // Önce kitabı al
        fetchBookById(id: bookId) { [weak self] book in
            guard let self = self else { return }
            
            // Kitap varsa ve resim URL'leri varsa önce onları sil
            if let book = book, !book.imageURLs.isEmpty {
                let dispatchGroup = DispatchGroup()
                
                for imageURL in book.imageURLs {
                    if let url = URL(string: imageURL), let imagePath = url.path.components(separatedBy: ".com/").last {
                        dispatchGroup.enter()
                        let imageRef = self.storage.child(imagePath)
                        
                        imageRef.delete { error in
                            if let error = error {
                                print("Resim silme hatası: \(error.localizedDescription)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    // Şimdi kitabı sil
                    self.deleteBookFromFirestore(bookId: bookId)
                }
            } else {
                // Resim yoksa doğrudan kitabı sil
                self.deleteBookFromFirestore(bookId: bookId)
            }
        }
    }
    
    // Kitap sil - Orijinal metod (completion handler ile)
    func deleteBook(bookId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Önce kitabı al
        fetchBookById(id: bookId) { [weak self] book in
            guard let self = self else { return }
            
            // Kitap varsa ve resim URL'leri varsa önce onları sil
            if let book = book, !book.imageURLs.isEmpty {
                let dispatchGroup = DispatchGroup()
                
                for imageURL in book.imageURLs {
                    if let url = URL(string: imageURL), let imagePath = url.path.components(separatedBy: ".com/").last {
                        dispatchGroup.enter()
                        let imageRef = self.storage.child(imagePath)
                        
                        imageRef.delete { error in
                            if let error = error {
                                print("Resim silme hatası: \(error.localizedDescription)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    // Şimdi kitabı sil
                    self.deleteBookFromFirestore(bookId: bookId, completion: completion)
                }
            } else {
                // Resim yoksa doğrudan kitabı sil
                self.deleteBookFromFirestore(bookId: bookId, completion: completion)
            }
        }
    }
    
    // Firestore'dan kitabı sil (completion handler olmadan)
    private func deleteBookFromFirestore(bookId: String) {
        db.collection("books").document(bookId).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Firestore'dan kitabı sil (completion handler ile)
    private func deleteBookFromFirestore(bookId: String, completion: @escaping (Bool) -> Void) {
        db.collection("books").document(bookId).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            completion(true)
        }
    }
} 