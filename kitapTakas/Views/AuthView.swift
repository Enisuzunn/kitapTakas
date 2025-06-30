import SwiftUI

struct AuthView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var tradeService: TradeService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var ratingService: RatingService
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background
                    .ignoresSafeArea()
                
            ScrollView {
                    VStack(spacing: 25) {
                    HStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoginMode = true
                            }
                        }) {
                            Text("Giriş Yap")
                                .fontWeight(isLoginMode ? .semibold : .medium)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(isLoginMode ? 
                                    ThemeColors.primary.opacity(0.3) : 
                                    ThemeColors.secondaryBackground.opacity(0.5))
                                .foregroundColor(isLoginMode ? 
                                    ThemeColors.primaryText : 
                                    ThemeColors.secondaryText)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ThemeColors.primary.opacity(0.6), lineWidth: isLoginMode ? 1.5 : 0)
                        )
                        .cornerRadius(10)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoginMode = false
                            }
                        }) {
                            Text("Kayıt Ol")
                                .fontWeight(isLoginMode ? .medium : .semibold)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(isLoginMode ? 
                                    ThemeColors.secondaryBackground.opacity(0.5) : 
                                    ThemeColors.primary.opacity(0.3))
                                .foregroundColor(isLoginMode ? 
                                    ThemeColors.secondaryText : 
                                    ThemeColors.primaryText)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ThemeColors.primary.opacity(0.6), lineWidth: isLoginMode ? 0 : 1.5)
                        )
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                        VStack(spacing: 15) {
                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(ThemeColors.primary)
                                .padding(.bottom, 10)
                    
                    Text("Kitap Takas")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(ThemeColors.primaryText)
                            
                            Text("Kitaplarınızı takas edin\nyeni dünyalar keşfedin")
                                .font(.system(size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundColor(ThemeColors.secondaryText)
                                .padding(.bottom, 20)
                        }
                        .padding(.vertical)
                        
                        VStack(spacing: 16) {
                    if !isLoginMode {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(ThemeColors.tertiaryText)
                                        .frame(width: 24)
                                    
                                    TextField("", text: $name)
                                        .placeholder(when: name.isEmpty) {
                                            Text("İsim")
                                                .foregroundColor(ThemeColors.tertiaryText)
                                        }
                                        .foregroundColor(.white)
                                        .autocapitalization(.none)
                                }
                                .padding()
                                .background(ThemeColors.secondaryBackground.opacity(0.7))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                                )
                                .padding(.horizontal)
                            }
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("E-posta")
                                            .foregroundColor(ThemeColors.tertiaryText)
                                    }
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Şifre")
                                            .foregroundColor(ThemeColors.tertiaryText)
                                    }
                                    .foregroundColor(.white)
                            }
                        .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                        .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                            )
                        .padding(.horizontal)
                        }
                        .padding(.vertical, 10)
                    
                    Button(action: handleAuth) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isLoginMode ? "Giriş Yap" : "Kayıt Ol")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        }
                        .buttonStyle(KitapTakasButtonStyle())
                        .padding(.horizontal)
                        .padding(.top, 10)
                    .disabled(isLoading)
                    
                        if !authService.errorMessage.isEmpty {
                            Text(authService.errorMessage)
                                .foregroundColor(ThemeColors.error)
                            .padding()
                    }
                        
                        if isLoginMode {
                            Button("Şifremi Unuttum") {
                                // Şifre sıfırlama işlevi
                            }
                            .foregroundColor(ThemeColors.primary)
                            .font(.subheadline)
                            .padding(.top, 5)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Hata"), 
                    message: Text(alertMessage), 
                    dismissButton: .default(Text("Tamam"))
                )
            }
        }
        .accentColor(ThemeColors.primary)
        .fullScreenCover(isPresented: $authService.isAuthenticated) {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(bookService)
                .environmentObject(tradeService)
                .environmentObject(chatService)
                .environmentObject(ratingService)
        }
    }
    
    private func handleAuth() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Lütfen tüm alanları doldurun"
            showingAlert = true
            return
        }
        
        if !isLoginMode && name.isEmpty {
            alertMessage = "Lütfen isminizi girin"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        if isLoginMode {
            authService.signIn(email: email, password: password) { success in
                isLoading = false
                if !success {
                    showingAlert = true
                    if !authService.errorMessage.isEmpty {
                    alertMessage = authService.errorMessage
                    } else {
                        alertMessage = "Giriş yaparken bir hata oluştu"
                    }
                }
            }
        } else {
            authService.signUp(name: name, email: email, password: password) { success in
                isLoading = false
                if !success {
                    showingAlert = true
                    if !authService.errorMessage.isEmpty {
                    alertMessage = authService.errorMessage
                    } else {
                        alertMessage = "Kayıt olurken bir hata oluştu"
                    }
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService.shared)
        .environmentObject(BookService())
        .environmentObject(TradeService())
        .environmentObject(ChatService())
        .environmentObject(RatingService())
} 