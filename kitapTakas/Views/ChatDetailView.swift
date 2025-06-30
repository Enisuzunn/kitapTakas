import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isScrollToBottom = false
    
    var otherParticipantName: String {
        if let userId = authService.user?.id {
            let otherParticipant = conversation.participants.first { $0 != userId } ?? ""
            return conversation.participantNames[otherParticipant] ?? "Bilinmeyen Kullanıcı"
        }
        return "Bilinmeyen Kullanıcı"
    }
    
    var body: some View {
        ZStack {
            ThemeColors.background.ignoresSafeArea()
            
            VStack {
                // İlgili kitap bilgisi (varsa)
                if let bookTitle = conversation.bookTitle, !bookTitle.isEmpty {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("İlgili kitap:")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                            
                            Text(bookTitle)
                                .font(.subheadline)
                                .foregroundColor(ThemeColors.primaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let bookId = conversation.bookId {
                            NavigationLink(destination: BookDetailView(bookId: bookId)) {
                                Text("Kitaba Git")
                                    .font(.footnote)
                                    .foregroundColor(ThemeColors.primary)
                            }
                        }
                    }
                    .padding()
                    .background(ThemeColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView("Mesajlar yükleniyor...")
                        .foregroundColor(ThemeColors.primaryText)
                        .padding()
                    Spacer()
                } else {
                    // Mesajlar listesi
                    ScrollView {
                        ScrollViewReader { proxy in
                            LazyVStack(spacing: 12) {
                                ForEach(chatService.messages) { message in
                                    MessageBubble(message: message, isFromCurrentUser: message.senderId == authService.user?.id)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .onChange(of: chatService.messages.count) { _ in
                                if let lastMessage = chatService.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                            .onAppear {
                                if let lastMessage = chatService.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        // Klavyeyi gizle
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                
                // Mesaj gönderme alanı
                HStack {
                    TextField("Mesaj yazın...", text: $messageText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(ThemeColors.secondaryBackground.opacity(0.7))
                        .foregroundColor(ThemeColors.primaryText)
                        .cornerRadius(20)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ThemeColors.primary)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(ThemeColors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
            }
        }
        .navigationTitle(otherParticipantName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
            markAsRead()
        }
        .onDisappear {
            // Dinleyiciyi temizle
            chatService.cleanupListeners()
        }
    }
    
    private func loadMessages() {
        guard let id = conversation.id else { return }
        
        isLoading = true
        chatService.getConversationMessages(conversationId: id)
        
        // Biraz gecikmeli olarak yükleme durumunu kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            markAsRead()
        }
    }
    
    private func markAsRead() {
        guard let userId = authService.user?.id, let id = conversation.id else { return }
        
        chatService.markMessagesAsRead(conversationId: id, userId: userId) { _ in
            // İşlem tamamlandı (başarılı veya başarısız)
        }
    }
    
    private func sendMessage() {
        guard let senderId = authService.user?.id,
              let senderName = authService.user?.name,
              let conversationId = conversation.id,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = "" // Metin alanını temizle
        
        chatService.addMessageToConversation(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            text: trimmedMessage
        ) { _, _ in
            // Mesaj gönderildi - listener otomatik olarak güncelleme yapacak
            markAsRead()
        }
    }
} 