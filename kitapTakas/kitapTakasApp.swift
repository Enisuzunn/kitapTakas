//
//  kitapTakasApp.swift
//  kitapTakas
//
//  Created by Enis Uzun on 13.05.2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

@main
struct kitapTakasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var bookService = BookService()
    @StateObject private var tradeService = TradeService()
    @StateObject private var chatService = ChatService()
    @StateObject private var ratingService = RatingService()
    
    init() {
        // Firebase yapılandırması
        FirebaseApp.configure()
        
        // Firestore ayarları - modern yaklaşım (deprecated uyarılarını gidermek için)
        let settings = FirestoreSettings()
        // Kullanımdan kaldırılan özellikler yerine cacheSettings kullanılıyor
        settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: MemoryLRUGCSettings())
        Firestore.firestore().settings = settings
        
        // Debug modda daha ayrıntılı Firebase logging'i
        #if DEBUG
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(bookService)
                    .environmentObject(tradeService)
                    .environmentObject(chatService)
                    .environmentObject(ratingService)
                    .onAppear {
                        // Kullanıcı giriş yaptığında takas tekliflerini dinlemeye başla
                        if let userId = authService.user?.id {
                            tradeService.listenForPendingOffers(userId: userId)
                        }
                    }
            } else {
                AuthView()
                    .environmentObject(authService)
                    .environmentObject(bookService)
                    .environmentObject(tradeService)
                    .environmentObject(chatService)
                    .environmentObject(ratingService)
            }
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Buradaki konfigürasyon kaldırıldı çünkü zaten kitapTakasApp init içinde yapılıyor
    return true
  }
}
