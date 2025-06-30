import SwiftUI
import PhotosUI

struct AddBookView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var bookService = BookService()
    @EnvironmentObject var authService: AuthService
    
    @State private var title = ""
    @State private var author = ""
    @State private var description = ""
    @State private var category = "Roman"
    @State private var condition = "İyi"
    @State private var isForTrade = true
    @State private var location = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    let conditions = ["Çok İyi", "İyi", "Orta", "Kötü"]
    let categories = ["Roman", "Bilim", "Kişisel Gelişim", "Tarih", "Felsefe", "Çocuk", "Diğer"]
    var editMode: Bool = false
    var bookToEdit: Book?
    
    init(editMode: Bool = false, bookToEdit: Book? = nil) {
        self.editMode = editMode
        self.bookToEdit = bookToEdit
        
        // Init değerlerini ayarla
        if let book = bookToEdit {
            _title = State(initialValue: book.title)
            _author = State(initialValue: book.author)
            _description = State(initialValue: book.description)
            _category = State(initialValue: book.category)
            _condition = State(initialValue: book.condition)
            _isForTrade = State(initialValue: book.isForTrade)
            
            if let bookLocation = book.location {
                _location = State(initialValue: bookLocation)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ThemeColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Kitap Bilgileri Bölümü
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KİTAP BİLGİLERİ")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ThemeColors.tertiaryText)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 16) {
                            // Kitap Adı
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                TextField("", text: $title)
                                    .placeholder(when: title.isEmpty) {
                                        Text("Kitap Adı")
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
                            
                            // Yazar
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                TextField("", text: $author)
                                    .placeholder(when: author.isEmpty) {
                                        Text("Yazar")
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
                            
                            // Kategori
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                Picker("", selection: $category) {
                                    ForEach(categories, id: \.self) {
                                        Text($0)
                                            .foregroundColor(.white)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.white)
                                .foregroundColor(.white)
                            }
                            .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                            )
                            
                            // Durum
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                Picker("", selection: $condition) {
                        ForEach(conditions, id: \.self) {
                            Text($0)
                                            .foregroundColor(.white)
                        }
                    }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.white)
                                .foregroundColor(.white)
                                .placeholder(when: false) {
                                    Text("Durum")
                                        .foregroundColor(ThemeColors.tertiaryText)
                                }
                            }
                            .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                            )
                            
                            // Konum
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .frame(width: 24)
                                
                                TextField("", text: $location)
                                    .placeholder(when: location.isEmpty) {
                                        Text("Konum (İsteğe bağlı)")
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
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Kitap Tipi Bölümü
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KİTAP TİPİ")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ThemeColors.tertiaryText)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 16) {
                            // Takas seçeneği
                            Toggle(isOn: $isForTrade) {
                        HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .foregroundColor(ThemeColors.primary)
                                    
                                    Text("Takas İçin")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ThemeColors.primary))
                            .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Kitap Açıklaması Bölümü
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KİTAP AÇIKLAMASI")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ThemeColors.tertiaryText)
                            .padding(.leading, 4)
                        
                        // Açıklama
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Kitap hakkında detaylı bilgi yazınız...")
                                    .foregroundColor(ThemeColors.tertiaryText)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                    TextEditor(text: $description)
                                .foregroundColor(.white)
                                .opacity(description.isEmpty ? 0.25 : 1)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                        }
                        .padding()
                        .background(ThemeColors.secondaryBackground.opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Kitap Kapağı Bölümü
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KİTAP KAPAĞI")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ThemeColors.tertiaryText)
                            .padding(.leading, 4)
                        
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(ThemeColors.primary)
                                
                                Text(selectedImage == nil ? "Resim Seç" : "Resmi Değiştir")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                            Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(ThemeColors.tertiaryText)
                            }
                            .padding()
                            .background(ThemeColors.secondaryBackground.opacity(0.7))
                            .cornerRadius(8)
                    }
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                                .frame(height: 220)
                                .cornerRadius(12)
                                .padding(.top, 8)
                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    }
                }
                    .padding(.horizontal)
                    
                    // Ekle/Güncelle Butonu
                    Button(action: editMode ? updateBook : addBook) {
                        HStack {
                            Spacer()
                            if bookService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Text(editMode ? "Kitabı Güncelle" : "Kitap Ekle")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            (title.isEmpty || author.isEmpty || description.isEmpty || bookService.isLoading) ?
                            ThemeColors.primary.opacity(0.5) : ThemeColors.primary
                        )
                        .cornerRadius(12)
                        .shadow(
                            color: ThemeColors.primary.opacity(0.3),
                            radius: 5, x: 0, y: 2
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .disabled(title.isEmpty || author.isEmpty || description.isEmpty || bookService.isLoading)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(editMode ? "Kitabı Düzenle" : "Yeni Kitap Ekle")
        .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Hata"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if bookService.isLoading {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text(editMode ? "Kitap Güncelleniyor..." : "Kitap Ekleniyor...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(ThemeColors.cardBackground)
                    .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                }
            )
        .onAppear {
            if editMode, let book = bookToEdit, let imageUrl = book.imageURLs.first, !imageUrl.isEmpty {
                loadImage(from: imageUrl)
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.selectedImage = image
                }
            }
        }.resume()
    }
    
    private func addBook() {
        guard let user = authService.user else {
            alertMessage = "Kullanıcı bilgisi bulunamadı."
            showingAlert = true
            return
        }
        
        let bookValueInt = 0
        
        let book = Book(
            title: title,
            author: author,
            description: description,
            price: nil,
            bookValue: bookValueInt,
            condition: condition,
            category: category,
            isForSale: false,
            isForTrade: isForTrade,
            imageURLs: [],
            ownerId: user.id ?? "",
            ownerDisplayName: user.name,
            location: location.isEmpty ? nil : location,
            status: "available"
        )
        
        var imageDataArray: [Data] = []
        if let selectedImage = selectedImage, let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            imageDataArray.append(imageData)
        }
        
        bookService.addBook(book: book, imageData: imageDataArray) { success, bookId in
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = bookService.errorMessage
                showError = true
            }
        }
    }
    
    private func updateBook() {
        guard let book = bookToEdit, let bookId = book.id else {
            alertMessage = "Düzenlenecek kitap bulunamadı."
            showingAlert = true
            return
        }
        
        var updatedData: [String: Any] = [
            "title": title,
            "author": author,
            "description": description,
            "condition": condition,
            "category": category,
            "isForSale": false,
            "isForTrade": isForTrade,
            "updatedAt": Date()
        ]
        
        if !location.isEmpty {
            updatedData["location"] = location
        }
        
        var imageDataArray: [Data] = []
        if let selectedImage = selectedImage, 
           let imageData = selectedImage.jpegData(compressionQuality: 0.8),
           !(book.imageURLs.count > 0 && selectedImage == self.selectedImage) {
            imageDataArray.append(imageData)
        }
        
        bookService.updateBook(bookId: bookId, data: updatedData, newImageData: imageDataArray.isEmpty ? nil : imageDataArray) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = bookService.errorMessage
                showError = true
            }
        }
    }
}

// ImagePicker struct'ını olduğu gibi bırakıyoruz
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    AddBookView()
        .environmentObject(AuthService())
} 