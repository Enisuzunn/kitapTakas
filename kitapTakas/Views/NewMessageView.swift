import SwiftUI

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService
    
    let receiverId: String
    let receiverName: String
    let bookId: String?
    let bookTitle: String?
    
    @State private var messageText: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if let bookTitle = bookTitle {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("İlgili kitap:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(bookTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Alıcı: \(receiverName)")
                        .font(.headline)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 150)
                        .padding(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.bottom)
                    
                    Button(action: sendMessage) {
                        Text("Mesaj Gönder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("Yeni Mesaj", displayMode: .inline)
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
            })
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
    }
    
    private func sendMessage() {
        guard let senderId = authService.user?.id, let senderName = authService.user?.name else {
            alertTitle = "Hata"
            alertMessage = "Kullanıcı bilgisi alınamadı."
            showAlert = true
            return
        }
        
        if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "Hata"
            alertMessage = "Lütfen bir mesaj yazın."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Konuşma katılımcıları ve isimleri
        let participants = [senderId, receiverId]
        let participantNames = [senderId: senderName, receiverId: receiverName]
        
        // Profil fotoğrafları varsa ekle (opsiyonel)
        var participantPhotos: [String: String] = [:]
        if let senderPhoto = authService.user?.profileImageUrl {
            participantPhotos[senderId] = senderPhoto
        }
        
        // Önce konuşma oluştur (veya varsa kullan)
        chatService.createConversation(
            participants: participants,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            bookId: bookId,
            bookTitle: bookTitle,
            bookImageURL: nil
        ) { success, conversationId in
            if success, let conversationId = conversationId {
                // Konuşmaya mesaj ekle
                chatService.addMessageToConversation(
                    conversationId: conversationId,
                    senderId: senderId,
                    senderName: senderName,
                    text: messageText
                ) { messageSent, _ in
                    isLoading = false
                    
                    if messageSent {
                        alertTitle = "Başarılı"
                        alertMessage = "Mesajınız gönderildi."
                    } else {
                        alertTitle = "Hata"
                        alertMessage = "Mesaj gönderilirken bir hata oluştu."
                    }
                    
                    showAlert = true
                }
            } else {
                isLoading = false
                alertTitle = "Hata"
                alertMessage = "Konuşma oluşturulurken bir hata meydana geldi."
                showAlert = true
            }
        }
    }
} 