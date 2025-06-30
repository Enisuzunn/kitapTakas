import Foundation
import Firebase
import FirebaseFirestore

class RatingService: ObservableObject {
    @Published var userRatings: [Rating] = []
    @Published var receivedRatings: [Rating] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    // Yeni değerlendirme oluştur
    func createRating(rating: Rating, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        do {
            let docRef = try db.collection("ratings").addDocument(from: rating)
            isLoading = false
            
            // AuthService üzerinden kullanıcı puanlamasını güncelle
            let authService = AuthService()
            authService.updateUserAverageRating(userId: rating.targetUserId) { _ in
                // Puan güncelleme başarılı olsa da olmasa da asıl değerlendirmeyi kaydetmeyi başarılı sayıyoruz
                completion(true, docRef.documentID)
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            completion(false, nil)
        }
    }
    
    // Kullanıcının yaptığı değerlendirmeleri getir
    func getUserRatings(userId: String) {
        isLoading = true
        
        db.collection("ratings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Değerlendirmeler yüklenemedi"
                    return
                }
                
                self.userRatings = documents.compactMap { document in
                    try? document.data(as: Rating.self)
                }
            }
    }
    
    // Kullanıcının aldığı değerlendirmeleri getir
    func getReceivedRatings(userId: String) {
        isLoading = true
        
        db.collection("ratings")
            .whereField("targetUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Değerlendirmeler yüklenemedi"
                    return
                }
                
                self.receivedRatings = documents.compactMap { document in
                    try? document.data(as: Rating.self)
                }
            }
    }
    
    // Kullanıcının değerlendirmelerini getir (callback olmadan)
    func fetchUserRatings(userId: String) {
        getReceivedRatings(userId: userId)
    }
    
    // Kullanıcının değerlendirmelerini getir (callback ile)
    func fetchUserRatings(userId: String, completion: @escaping ([Rating]) -> Void) {
        isLoading = true
        
        db.collection("ratings")
            .whereField("targetUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { 
                    completion([])
                    return 
                }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Değerlendirmeler yüklenemedi"
                    completion([])
                    return
                }
                
                let ratings = documents.compactMap { document in
                    try? document.data(as: Rating.self)
                }
                
                // Aynı zamanda receivedRatings'i de güncelle
                self.receivedRatings = ratings
                
                completion(ratings)
            }
    }
    
    // Kullanıcının ortalama puanını hesapla
    func calculateUserAverageRating(userId: String, completion: @escaping (Double, Int) -> Void) {
        isLoading = true
        
        db.collection("ratings")
            .whereField("targetUserId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(0.0, 0)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(0.0, 0)
                    return
                }
                
                let ratings = documents.compactMap { doc -> Int? in
                    return doc.data()["rating"] as? Int
                }
                
                let totalRatings = ratings.count
                let sum = ratings.reduce(0, +)
                let average = totalRatings > 0 ? Double(sum) / Double(totalRatings) : 0.0
                
                completion(average, totalRatings)
            }
    }
    
    // Değerlendirmeyi güncelle
    func updateRating(id: String, data: [String: Any], completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("ratings").document(id).updateData(data) { [weak self] error in
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
    
    // Değerlendirmeyi sil
    func deleteRating(id: String, targetUserId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("ratings").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            // Kullanıcının ortalama puanını güncelle
            let authService = AuthService()
            authService.updateUserAverageRating(userId: targetUserId) { success in
                self.isLoading = false
                completion(success)
            }
        }
    }
    
    // Kullanıcının değerlendirmelerini getir (async/await)
    func fetchUserRatingsAsync(userId: String) async -> [Rating] {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("ratings")
                .whereField("targetUserId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            let ratings = snapshot.documents.compactMap { document in
                try? document.data(as: Rating.self)
            }
            
            DispatchQueue.main.async {
                self.receivedRatings = ratings
            }
            
            return ratings
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            return []
        }
    }
} 