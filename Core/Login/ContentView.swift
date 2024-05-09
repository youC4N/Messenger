import SwiftUI
import PhotosUI

struct ContentView: View {
    
    //MARK: - Properties
    //@State private var selectedItem: [PhotosPickerItem] = [PhotosPickerItem]() // use to select multiple images from gallery
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    //MARK: - Body
    
    var body: some View {
        VStack {
                PhotosPicker(
                    selection: $selectedItem,
                   // maxSelectionCount: 2, //set max selection from gallery
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Choose Photos from Gallery")
                        .frame(width: 350, height: 50)
                        .background(Capsule().stroke(lineWidth: 2))
                }
                .onChange(of: selectedItem) { newValue in
                    Task { // Incase of multiple selection newValue is of array type
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16).stroke(Color.yellow, lineWidth: 8)
                    )
            }
        }
        .padding()
    }
}

#Preview{
    ContentView()
}
