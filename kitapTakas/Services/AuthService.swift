import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // Singleton instance
    static let shared = AuthService()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                self?.isAuthenticated = true
                self?.fetchUserData(uid: firebaseUser.uid)
            } else {
                self?.isAuthenticated = false
                self?.user = nil
            }
        }
    }
    
    // Giriş işlemi
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            if let user = result?.user {
                self.fetchUserData(uid: user.uid)
                completion(true)
            }
        }
    }
    
    // Kayıt işlemi
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            if let user = result?.user {
                let now = Date()
                let userData = User(
                    id: user.uid,
                    name: name,
                    email: email,
                    averageRating: 0.0,
                    totalRatings: 0,
                    completedTrades: 0,
                    createdAt: now,
                    updatedAt: now
                )
                
                do {
                    try self.db.collection("users").document(user.uid).setData(from: userData)
                    self.user = userData
                    self.isAuthenticated = true
                    completion(true)
                } catch {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // Çıkış işlemi
    func signOut() {
        do {
            try auth.signOut()
            isAuthenticated = false
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Kullanıcı verilerini getir
    func fetchUserData(uid: String) {
        isLoading = true
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let userData = try? document?.data(as: User.self) {
                DispatchQueue.main.async {
                    self.user = userData
                }
            }
        }
    }
    
    // Profil güncelleme
    func updateProfile(userId: String, userData: [String: Any], completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        var updatedData = userData
        updatedData["updatedAt"] = Date()
        
        db.collection("users").document(userId).updateData(updatedData) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            // Kullanıcı verilerini yeniden yükle
            self.fetchUserData(uid: userId)
            completion(true)
        }
    }
    
    // Profil resmi yükle
    func uploadProfileImage(userId: String, imageData: Data, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        let fileRef = storage.child("profileImages/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        fileRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false, nil)
                return
            }
            
            fileRef.downloadURL { [weak self] url, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false, nil)
                    return
                }
                
                if let url = url {
                    // Profil resmini güncelle
                    self.updateProfile(userId: userId, userData: ["profileImageUrl": url.absoluteString]) { success in
                        completion(success, url.absoluteString)
                    }
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    // Tamamlanan takas sayısını artır
    func incrementCompletedTrades(userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Önce kullanıcı verilerini al
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                self.errorMessage = "Kullanıcı bulunamadı"
                self.isLoading = false
                completion(false)
                return
            }
            
            // Tamamlanan takas sayısını artır
            let currentTrades = snapshot.data()?["completedTrades"] as? Int ?? 0
            let newTradeCount = currentTrades + 1
            
            self.db.collection("users").document(userId).updateData([
                "completedTrades": newTradeCount,
                "updatedAt": Date()
            ]) { error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                // Kullanıcı verisini güncelle
                if self.user?.id == userId {
                    self.user?.completedTrades = newTradeCount
                }
                
                completion(true)
            }
        }
    }
    
    // Kullanıcının ortalama puanını güncelle
    func updateUserAverageRating(userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Kullanıcının tüm derecelendirmelerini al
        db.collection("ratings")
            .whereField("targetUserId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // Derecelendirme yoksa, sıfırla
                    self.db.collection("users").document(userId).updateData([
                        "averageRating": 0.0,
                        "totalRatings": 0,
                        "updatedAt": Date()
                    ]) { error in
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                    return
                }
                
                // Ortalama puanı hesapla
                let ratings = documents.compactMap { doc -> Int? in
                    return doc.data()["rating"] as? Int
                }
                
                let totalRatings = ratings.count
                let sum = ratings.reduce(0, +)
                let average = totalRatings > 0 ? Double(sum) / Double(totalRatings) : 0.0
                
                // Kullanıcı bilgilerini güncelle
                self.db.collection("users").document(userId).updateData([
                    "averageRating": average,
                    "totalRatings": totalRatings,
                    "updatedAt": Date()
                ]) { error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(false)
                        return
                    }
                    
                    // Kullanıcı verisini güncelle
                    if self.user?.id == userId {
                        self.user?.averageRating = average
                        self.user?.totalRatings = totalRatings
                    }
                    
                    completion(true)
                }
            }
    }
} 