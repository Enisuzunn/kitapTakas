import SwiftUI

struct UserBookCard: View {
    @EnvironmentObject var bookService: BookService
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Kitap görseli
                if let firstImage = book.imageURLs.first, let url = URL(string: firstImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 90)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 90)
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 90)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 90)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title)
                        .font(.headline)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingEditView = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingEditView) {
            NavigationView {
                AddBookView(editMode: true, bookToEdit: book)
                    .navigationTitle("Kitabı Düzenle")
            }
        }
    }
}

struct UserBookCard_Previews: PreviewProvider {
    static var previews: some View {
        UserBookCard(book: Book(
            title: "Örnek Kitap",
            author: "Yazar",
            description: "Açıklama",
            bookValue: 0,
            condition: "İyi",
            category: "Roman",
            isForSale: true,
            isForTrade: true,
            imageURLs: [],
            ownerId: "1",
            ownerDisplayName: "Kullanıcı"
        ))
        .environmentObject(BookService())
    }
} 