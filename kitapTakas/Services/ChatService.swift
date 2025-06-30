import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatService: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // Okunmamış mesaj kontrolü için hesaplanmış özellik
    var hasUnreadMessages: Bool {
        guard let userId = AuthService.shared.user?.id else { return false }
        
        for conversation in conversations {
            if let unreadCount = conversation.unreadCount?[userId], unreadCount > 0 {
                return true
            }
        }
        return false
    }
    
    private let db = Firestore.firestore()
    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    
    // Yeni konuşma oluştur
    func createConversation(participants: [String], participantNames: [String: String], participantPhotos: [String: String]?, bookId: String? = nil, bookTitle: String? = nil, bookImageURL: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Önce mevcut konuşmaları kontrol et (aynı katılımcılarla)
        let sortedParticipants = participants.sorted()
        
        db.collection("conversations")
            .whereField("participants", isEqualTo: sortedParticipants)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // Aynı katılımcılarla mevcut bir konuşma var mı?
                if let documents = snapshot?.documents, !documents.isEmpty {
                    // Mevcut konuşma varsa, onu kullan
                    if let existingConversation = try? documents[0].data(as: Conversation.self),
                       let conversationId = existingConversation.id {
                        
                        // Kitap bilgilerini güncelle (gerekirse)
                        if (bookId != nil && bookId != existingConversation.bookId) || 
                           (bookTitle != nil && bookTitle != existingConversation.bookTitle) {
                            
                            var updateData: [String: Any] = [:]
                            
                            if let bookId = bookId {
                                updateData["bookId"] = bookId
                            }
                            if let bookTitle = bookTitle {
                                updateData["bookTitle"] = bookTitle
                            }
                            if let bookImageURL = bookImageURL {
                                updateData["bookImageURL"] = bookImageURL
                            }
                            
                            self.db.collection("conversations").document(conversationId).updateData(updateData)
                        }
                        
                        self.isLoading = false
                        completion(true, conversationId)
                        return
                    }
                }
                
                // Yeni konuşma oluştur
                var unreadCount: [String: Int] = [:]
                for participant in participants {
                    unreadCount[participant] = 0
                }
        
        let conversation = Conversation(
                    participants: sortedParticipants,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
                    unreadCount: unreadCount,
            bookId: bookId,
            bookTitle: bookTitle,
            bookImageURL: bookImageURL,
            createdAt: Date()
        )
        
        do {
                    let docRef = try self.db.collection("conversations").addDocument(from: conversation)
                    self.isLoading = false
            completion(true, docRef.documentID)
        } catch {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
            completion(false, nil)
                }
        }
    }
    
    // Kullanıcının konuşmalarını gerçek zamanlı olarak dinle
    func getUserConversations(userId: String) {
        isLoading = true
        
        // Eski dinleyiciyi iptal et
        conversationsListener?.remove()
        
        // Yeni dinleyici oluştur
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Konuşmalar yüklenemedi"
                    return
                }
                
                self.conversations = documents.compactMap { document in
                    try? document.data(as: Conversation.self)
                }
            }
    }
    
    // Konuşmaya mesaj ekle
    func addMessageToConversation(conversationId: String, senderId: String, senderName: String, text: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        let message = Message(
            text: text,
            senderId: senderId,
            senderName: senderName,
            timestamp: Date(),
            read: false
        )
        
        // Mesaj koleksiyonu için yol
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        do {
            let docRef = try messagesRef.addDocument(from: message)
            
            // Konuşma belgesini al
            db.collection("conversations").document(conversationId).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    completion(false, nil)
                    return
                }
                
                do {
                    if let snapshot = snapshot, snapshot.exists,
                       var conversation = try? snapshot.data(as: Conversation.self) {
                        
                        // Okunmamış mesaj sayacını güncelle
                        var unreadCount = conversation.unreadCount ?? [:]
                        
                        // Gönderenin dışındaki tüm katılımcılar için okunmamış sayısını artır
                        for participant in conversation.participants {
                            if participant != senderId {
                                unreadCount[participant] = (unreadCount[participant] ?? 0) + 1
                            }
                        }
                        
                        // Konuşma dokümanını güncelle
                        self.db.collection("conversations").document(conversationId).updateData([
                            "lastMessage": text,
                            "lastMessageTimestamp": Date(),
                            "lastMessageSenderId": senderId,
                            "unreadCount": unreadCount
                        ]) { error in
                            self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false, nil)
                    return
                }
                
                completion(true, docRef.documentID)
                        }
                    } else {
                        self.isLoading = false
                        self.errorMessage = "Konuşma bilgisi bulunamadı"
                        completion(false, nil)
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false, nil)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            completion(false, nil)
        }
    }
    
    // Konuşma mesajlarını gerçek zamanlı olarak dinle
    func getConversationMessages(conversationId: String) {
        isLoading = true
        
        // Eski dinleyiciyi iptal et
        messagesListener?.remove()
        
        // Yeni dinleyici oluştur
        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Mesajlar yüklenemedi"
                    return
                }
                
                self.messages = documents.compactMap { document in
                    try? document.data(as: Message.self)
                }
            }
    }
    
    // Okunmamış mesajları işaretle
    func markMessagesAsRead(conversationId: String, userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Önce konuşma belgesini alıp okunmamış sayısını sıfırla
        db.collection("conversations").document(conversationId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            if var conversation = try? snapshot?.data(as: Conversation.self),
               var unreadCount = conversation.unreadCount {
                // Bu kullanıcı için okunmamış sayısını sıfırla
                unreadCount[userId] = 0
                
                // Konuşma belgesini güncelle
                self.db.collection("conversations").document(conversationId).updateData([
                    "unreadCount": unreadCount
                ])
            }
            
            // Mesajları okundu olarak işaretle
            let messagesRef = self.db.collection("conversations").document(conversationId).collection("messages")
        
        // Bu kullanıcıya ait olmayan ve okunmamış mesajları bul
        messagesRef
            .whereField("senderId", isNotEqualTo: userId)
            .whereField("read", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.isLoading = false
                    completion(true)
                    return
                }
                
                // Batch update kullanarak tüm mesajları işaretle
                let batch = self.db.batch()
                
                for document in documents {
                    let docRef = messagesRef.document(document.documentID)
                    batch.updateData(["read": true], forDocument: docRef)
                }
                
                // Batch işlemi çalıştır
                batch.commit { [weak self] error in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                        }
                    }
                }
            }
    }
    
    // Konuşmayı sil
    func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Önce tüm mesajları sil
        let messagesRef = db.collection("conversations").document(conversationId).collection("messages")
        
        messagesRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
                return
            }
            
            // Batch silme işlemi
            let batch = self.db.batch()
            
            snapshot?.documents.forEach { document in
                batch.deleteDocument(messagesRef.document(document.documentID))
            }
            
            // Ana konuşma dokümanını da sil
            batch.deleteDocument(self.db.collection("conversations").document(conversationId))
            
            // Batch işlemi çalıştır
            batch.commit { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // Dinleyicileri temizle (genellikle view disappear olduğunda)
    func cleanupListeners() {
        conversationsListener?.remove()
        messagesListener?.remove()
        conversationsListener = nil
        messagesListener = nil
    }
    
    deinit {
        cleanupListeners()
    }
} 