import SwiftUI

// View+Extensions.swift dosyasının içeriğini buraya taşıyıp ThemeManager.swift içeriğini genişletiyorum
// View için gerekli extension'lar
extension View {
    // Placeholder ekleme fonksiyonu
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    // Diğer View extension'ları buraya eklenebilir
    
    func kitapTakasCard() -> some View {
        modifier(KitapTakasCardViewStyle())
    }
}

struct ThemeColors {
    // Ana renkler
    static let primary = Color(hex: "9333EA") // Ana mor renk
    static let secondary = Color(hex: "4F46E5") // İndigo tonu
    static let accent = Color(hex: "EC4899") // Pembe vurgu rengi
    
    // Arka plan renkleri
    static let background = Color(hex: "10002B") // Çok koyu mor zemin
    static let secondaryBackground = Color(hex: "240046") // Orta koyu mor zemin
    static let cardBackground = Color(hex: "3C096C") // Daha açık mor kart zemini
    
    // Metin renkleri
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "D8B4FE") // Lavanta açık ton
    static let tertiaryText = Color(hex: "C084FC") // Orta açıklıkta mor
    
    // Vurgu ve işlem renkleri
    static let success = Color(hex: "10B981") // Yeşil/Mint
    static let warning = Color(hex: "FBBF24") // Sarı/Amber
    static let error = Color(hex: "EF4444") // Kırmızı
    static let info = Color(hex: "3B82F6") // Mavi
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct KitapTakasButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: ThemeColors.primary.opacity(0.5), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct KitapTakasSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(ThemeColors.secondaryBackground.opacity(0.7))
            .foregroundColor(ThemeColors.secondaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary, ThemeColors.accent]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: ThemeColors.accent.opacity(0.3), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct KitapTakasTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ThemeColors.secondaryBackground.opacity(0.6))
            .foregroundColor(.white)
            .accentColor(ThemeColors.accent) // İmleç rengi güncellendi
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.6), ThemeColors.accent.opacity(0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: ThemeColors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct KitapTakasCardViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [ThemeColors.primary.opacity(0.3), ThemeColors.accent.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
} 