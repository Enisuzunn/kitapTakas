import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService
    
    @State private var isLoading: Bool = false
    @State private var showingNewMessage = false
    
    var body: some View {
        ZStack {
            ThemeColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Text("Mesajlar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeColors.primaryText)
                    
                    Spacer()
                    
                    // Yeni mesaj butonu - NavigationLink yerine sheet kullanıyoruz
                    Button(action: {
                        showingNewMessage = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(ThemeColors.secondaryBackground.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(ThemeColors.accent)
                        .padding()
                    
                    Text("Mesajlar yükleniyor...")
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                        .padding(.top, 10)
                    Spacer()
                } else if chatService.conversations.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [ThemeColors.primary.opacity(0.2), ThemeColors.accent.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: ThemeColors.primary.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                        
                        Text("Henüz mesajınız yok")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeColors.primaryText)
                        
                        Text("Diğer kullanıcılarla kitaplar hakkında mesajlaşmak için kitap detaylarına gidin ve mesaj gönderin.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(ThemeColors.secondaryText)
                            .padding(.horizontal, 30)
                        
                        Button(action: {
                            // Ana sayfaya yönlendir
                        }) {
                            Text("Kitapları Keşfedin")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: ThemeColors.primary.opacity(0.4), radius: 6, x: 0, y: 3)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(chatService.conversations) { conversation in
                                NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                                    ConversationRow(conversation: conversation)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            loadConversations()
        }
        .onDisappear {
            // Dinleyicileri temizle
            chatService.cleanupListeners()
        }
        .refreshable {
            loadConversations()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNewMessage) {
            // Yeni mesaj görünümü için gerekli parametreleri sağlıyoruz
            // Kullanıcı ilk önce alıcı seçmesi gerektiği için geçici değerler kullanıyoruz
            NewMessageView(
                receiverId: "",
                receiverName: "Alıcı seçin",
                bookId: nil,
                bookTitle: nil
            )
            .environmentObject(authService)
            .environmentObject(chatService)
        }
    }
    
    private func loadConversations() {
        guard let userId = authService.user?.id else { return }
        
        isLoading = true
        chatService.getUserConversations(userId: userId)
        
        // Biraz gecikmeli olarak yükleme durumunu kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    @EnvironmentObject var authService: AuthService
    
    var otherParticipantName: String {
        if let userId = authService.user?.id {
            // Kullanıcının kendisi dışındaki katılımcının adını göster
            let otherParticipant = conversation.participants.first { $0 != userId } ?? ""
            return conversation.participantNames[otherParticipant] ?? "Bilinmeyen Kullanıcı"
        }
        return "Bilinmeyen Kullanıcı"
    }
    
    // Okunmamış mesaj sayısı
    var unreadCount: Int {
        if let userId = authService.user?.id,
           let count = conversation.unreadCount?[userId] {
            return count
        }
        return 0
    }
    
    // Bu kullanıcı son mesajı gönderen mi
    var isLastMessageFromCurrentUser: Bool {
        if let userId = authService.user?.id,
           let senderId = conversation.lastMessageSenderId {
            return senderId == userId
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Profil resmi
            ZStack {
                if let userId = authService.user?.id,
                   let otherParticipantId = conversation.participants.first(where: { $0 != userId }),
                   let photoURL = conversation.participantPhotos?[otherParticipantId],
                   let url = URL(string: photoURL) {
                    
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.primary.opacity(0.7), ThemeColors.accent.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [ThemeColors.primary.opacity(0.7), ThemeColors.accent.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)
                }
                
                // Okunmamış mesaj göstergesi
                if unreadCount > 0 {
                    Circle()
                        .fill(ThemeColors.primary)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Text("\(min(unreadCount, 9))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(ThemeColors.background, lineWidth: 2)
                        )
                        .offset(x: 20, y: -20)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Katılımcı adı
                Text(otherParticipantName)
                    .font(.system(size: 16, weight: unreadCount > 0 ? .bold : .semibold))
                    .foregroundColor(ThemeColors.primaryText)
                
                // Kitap bilgisi (varsa)
                if let bookTitle = conversation.bookTitle, !bookTitle.isEmpty {
                    Text("Kitap: \(bookTitle)")
                        .font(.system(size: 13))
                        .foregroundColor(ThemeColors.accent.opacity(0.9))
                }
                
                // Son mesaj (varsa)
                if let lastMessage = conversation.lastMessage {
                    HStack(spacing: 4) {
                        // Gönderen işareti
                        if isLastMessageFromCurrentUser {
                            Text("Siz:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .foregroundColor(unreadCount > 0 ? ThemeColors.primaryText : ThemeColors.secondaryText)
                            .fontWeight(unreadCount > 0 ? .medium : .regular)
                    }
                }
            }
            
            Spacer()
            
            // Son mesaj zamanı
            VStack(alignment: .trailing) {
                if let timestamp = conversation.lastMessageTimestamp {
                    Text(formatTimestamp(timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(unreadCount > 0 ? ThemeColors.primary : ThemeColors.tertiaryText)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(unreadCount > 0 ? 
                      ThemeColors.cardBackground.opacity(0.95) :
                      ThemeColors.cardBackground.opacity(0.7))
                .shadow(color: unreadCount > 0 ? 
                        ThemeColors.primary.opacity(0.3) : 
                        Color.black.opacity(0.1), 
                        radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            unreadCount > 0 ? ThemeColors.primary.opacity(0.5) : ThemeColors.primary.opacity(0.2),
                            unreadCount > 0 ? ThemeColors.accent.opacity(0.5) : ThemeColors.accent.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        MessagesView()
            .environmentObject(AuthService())
            .environmentObject(ChatService())
    }
} 