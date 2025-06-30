import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Material design arka planı
                ThemeColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Başlık
                    Text("More")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ThemeColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Menu kartı
                    VStack(spacing: 0) {
                        // Mesajlar butonu
                        NavigationLink(destination: MessagesView()) {
                            HStack(spacing: 16) {
                                // İkon kısmı
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [ThemeColors.primary.opacity(0.7), ThemeColors.accent.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Mesajlar")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ThemeColors.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeColors.tertiaryText)
                            }
                            .padding(16)
                        }
                        
                        Divider()
                            .background(ThemeColors.tertiaryText.opacity(0.2))
                            .padding(.leading, 76)
                        
                        // Profil butonu
                        NavigationLink(destination: ProfileView()) {
                            HStack(spacing: 16) {
                                // İkon kısmı
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [ThemeColors.accent.opacity(0.7), ThemeColors.primary.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .shadow(color: ThemeColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Profil")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ThemeColors.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeColors.tertiaryText)
                            }
                            .padding(16)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ThemeColors.cardBackground.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [ThemeColors.primary.opacity(0.3), ThemeColors.accent.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Sürüm bilgisi
                    Text("Kitap Takas v1.0.0")
                        .font(.caption)
                        .foregroundColor(ThemeColors.tertiaryText)
                        .padding(.bottom, 10)
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(ThemeColors.primary)
    }
}

#Preview {
    MoreView()
        .environmentObject(AuthService())
} 