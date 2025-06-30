import SwiftUI

struct RatingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    let targetUserId: String
    let bookId: String?
    let offerId: String?
    
    @StateObject private var ratingService = RatingService()
    
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Değerlendirme")) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Kullanıcıyı değerlendirin")
                            .font(.headline)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .font(.title)
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Yorum")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: submitRating) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Değerlendirmeyi Gönder")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Değerlendirme")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
            })
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
    
    private func submitRating() {
        guard let userId = authService.user?.id else {
            alertTitle = "Hata"
            alertMessage = "Kullanıcı bilgileri alınamadı."
            showAlert = true
            return
        }
        
        if comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = "Hata"
            alertMessage = "Lütfen bir yorum ekleyin."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let now = Date()
        let ratingData = Rating(
            userId: userId,
            targetUserId: targetUserId,
            rating: rating,
            comment: comment,
            bookId: bookId,
            createdAt: now
        )
        
        ratingService.createRating(rating: ratingData) { success, _ in
            isLoading = false
            
            if success {
                // Eğer takas teklifi varsa, derecelendirme yapıldığını işaretle
                updateTradeOfferRating(success)
            } else {
                alertTitle = "Hata"
                alertMessage = "Değerlendirme gönderilirken bir hata oluştu."
                showAlert = true
            }
        }
    }
    
    private func updateTradeOfferRating(_ ratingSuccess: Bool) {
        guard let offerId = offerId else {
            showCompletionAlert(ratingSuccess)
            return
        }
        
        // Değerlendirme yapan kim olduğuna göre işaretle
        if let currentUserId = authService.user?.id, currentUserId == targetUserId {
            // Eğer hedef kullanıcı değerlendiren kullanıcı ile aynıysa, alıcı olarak işaretle
            let tradeService = TradeService()
            tradeService.updateTradeOffer(id: offerId, data: ["receiverRated": true]) { success in
                showCompletionAlert(ratingSuccess && success)
            }
        } else {
            // Teklifin sahibi olarak işaretle
            let tradeService = TradeService()
            tradeService.updateTradeOffer(id: offerId, data: ["offererRated": true]) { success in
                showCompletionAlert(ratingSuccess && success)
            }
        }
    }
    
    private func showCompletionAlert(_ success: Bool) {
        if success {
            alertTitle = "Başarılı"
            alertMessage = "Değerlendirmeniz için teşekkürler!"
        } else {
            alertTitle = "Hata"
            alertMessage = "Değerlendirme kaydedilirken bir hata oluştu."
        }
        showAlert = true
    }
}

struct UserRatingsView: View {
    let userId: String
    
    @StateObject private var ratingService = RatingService()
    @State private var isLoading = true
    @State private var averageRating = 0.0
    @State private var totalRatings = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView("Değerlendirmeler yükleniyor...")
                    .padding()
            } else if ratingService.receivedRatings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Henüz değerlendirme yok")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Bu kullanıcıya ait değerlendirme bulunmamaktadır.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Ortalama puan göstergesi
                HStack(alignment: .center, spacing: 16) {
                    VStack {
                        Text(String(format: "%.1f", averageRating))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text("\(totalRatings) değerlendirme")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Değerlendirmeler listesi
                List {
                    ForEach(ratingService.receivedRatings) { rating in
                        RatingRow(rating: rating)
                    }
                }
            }
        }
        .navigationTitle("Değerlendirmeler")
        .onAppear {
            loadRatings()
        }
        .refreshable {
            loadRatings()
        }
    }
    
    private func loadRatings() {
        isLoading = true
        
        ratingService.getReceivedRatings(userId: userId)
        
        ratingService.calculateUserAverageRating(userId: userId) { average, count in
            averageRating = average
            totalRatings = count
            isLoading = false
        }
    }
}

struct RatingRow: View {
    let rating: Rating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Yıldızları göster
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                // Değerlendirme tarihi
                Text(formatDate(rating.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Yorumu göster
            Text(rating.comment)
                .font(.body)
                .foregroundColor(.primary)
            
            if let bookId = rating.bookId, !bookId.isEmpty {
                NavigationLink(destination: BookDetailView(bookId: bookId)) {
                    Text("İlgili kitabı gör")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 