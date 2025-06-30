import Foundation
import Firebase
import FirebaseFirestore

class TradeService: ObservableObject {
    @Published var sentOffers: [TradeOffer] = []
    @Published var receivedOffers: [TradeOffer] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var pendingReceivedCount: Int = 0
    
    // En son tamamlanan takas teklifleri sayısı
    // Bu sayede son tamamlanan X adet takas gösterilir, eskiler saklanır
    private let completedOffersToShow = 5
    
    private let db = Firestore.firestore()
    private var pendingOffersListener: ListenerRegistration?
    
    deinit {
        // Listener'ı temizle
        pendingOffersListener?.remove()
    }
    
    // Takas teklifi oluştur
    func createTradeOffer(offer: TradeOffer, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        do {
            let docRef = try db.collection("tradeOffers").addDocument(from: offer)
            isLoading = false
            completion(true, docRef.documentID)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            completion(false, nil)
        }
    }
    
    // ID'ye göre takas teklifi getir
    func getTradeOffer(id: String, completion: @escaping (TradeOffer?) -> Void) {
        isLoading = true
        
        db.collection("tradeOffers").document(id).getDocument { [weak self] snapshot, error in
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
            
            let offer = try? snapshot.data(as: TradeOffer.self)
            completion(offer)
        }
    }
    
    // Kullanıcının aldığı teklifleri getir
    func getReceivedTradeOffers(userId: String) {
        isLoading = true
        
        db.collection("tradeOffers")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Teklifler yüklenemedi"
                    return
                }
                
                self.receivedOffers = documents.compactMap { document in
                    try? document.data(as: TradeOffer.self)
                }
                
                // Bekleyen teklif sayısını güncelle
                self.pendingReceivedCount = self.receivedOffers.filter { $0.status == "pending" }.count
            }
    }
    
    // Kullanıcının gönderdiği teklifleri getir
    func getSentTradeOffers(userId: String) {
        isLoading = true
        
        db.collection("tradeOffers")
            .whereField("offererId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Teklifler yüklenemedi"
                    return
                }
                
                self.sentOffers = documents.compactMap { document in
                    try? document.data(as: TradeOffer.self)
                }
            }
    }
    
    // Bekleyen takas tekliflerini dinle
    func listenForPendingOffers(userId: String) {
        // Önceki listener'ı temizle
        pendingOffersListener?.remove()
        
        // Firestore'da bekleyen teklifleri dinle
        pendingOffersListener = db.collection("tradeOffers")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                    return
                }
                
                self.pendingReceivedCount = snapshot.documents.count
                
                // Yeni teklifler geldiğinde receivedOffers listesini de güncelle
                if !snapshot.documents.isEmpty {
                    let newOffers = snapshot.documents.compactMap { document -> TradeOffer? in
                        try? document.data(as: TradeOffer.self)
                    }
                    
                    // Mevcut receivedOffers'ı güncelle (bekleyen teklifler için)
                    let existingNonPendingOffers = self.receivedOffers.filter { $0.status != "pending" }
                    self.receivedOffers = existingNonPendingOffers + newOffers
                }
            }
    }
    
    // Kullanıcının bekleyen tüm takas tekliflerini sayıp döndüren fonksiyon
    func countPendingOffers(userId: String, completion: @escaping (Int) -> Void) {
        db.collection("tradeOffers")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Takas teklifi sayısı alınamadı: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    // Async/await versiyonu - Kullanıcının aldığı teklifleri getir
    func getReceivedTradeOffersAsync(userId: String) async throws -> [TradeOffer] {
        let snapshot = try await db.collection("tradeOffers")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: TradeOffer.self)
        }
    }
    
    // Async/await versiyonu - Kullanıcının gönderdiği teklifleri getir
    func getSentTradeOffersAsync(userId: String) async throws -> [TradeOffer] {
        let snapshot = try await db.collection("tradeOffers")
            .whereField("offererId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: TradeOffer.self)
            }
    }
    
    // Takas teklifi durumunu güncelle
    func updateTradeOfferStatus(id: String, status: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("tradeOffers").document(id).updateData([
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
    
    // Takas teklifi verilerini güncelle
    func updateTradeOffer(id: String, data: [String: Any], completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        var updatedData = data
        updatedData["updatedAt"] = Date()
        
        db.collection("tradeOffers").document(id).updateData(updatedData) { [weak self] error in
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
    
    // Takas teklifini sil
    func deleteTradeOffer(id: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("tradeOffers").document(id).delete { [weak self] error in
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
    
    // Sadece belirli sayıda tamamlanmış teklifi göster, diğerlerini gizle
    func filterCompletedOffers() {
        // Gelen teklifleri filtrele
        let completedReceived = receivedOffers.filter { $0.status == "completed" }
        let nonCompletedReceived = receivedOffers.filter { $0.status != "completed" }
        
        // En son tamamlanan X adet teklifi göster
        let latestCompletedReceived = Array(completedReceived.prefix(completedOffersToShow))
        receivedOffers = nonCompletedReceived + latestCompletedReceived
        
        // Gönderilen teklifler için aynı işlemi yap
        let completedSent = sentOffers.filter { $0.status == "completed" }
        let nonCompletedSent = sentOffers.filter { $0.status != "completed" }
        
        // En son tamamlanan X adet teklifi göster
        let latestCompletedSent = Array(completedSent.prefix(completedOffersToShow))
        sentOffers = nonCompletedSent + latestCompletedSent
    }
} 