//
//  ContentView.swift
//  kitapTakas
//
//  Created by Enis Uzun on 13.05.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var bookService = BookService()
    @StateObject private var tradeService = TradeService()
    @StateObject private var chatService = ChatService()
    @StateObject private var ratingService = RatingService()
    
    var body: some View {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                .environmentObject(bookService)
                .environmentObject(tradeService)
                .environmentObject(chatService)
                .environmentObject(ratingService)
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

#Preview {
    ContentView()
}
