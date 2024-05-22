import PhotosUI
import SwiftUI

struct Registration: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State var username = ""
    var token: String
    var onLoginComplete: () -> Void
    func validate(_ name: String) -> Bool {
        // TODO: validate the code
        return true
    }
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {

                if let selectedImage = selectedImage {

                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 80, minHeight: 80)
                        .clipShape(Circle())

                } else {
                    ZStack {
                        Image(systemName: "person")
                            .resizable()
                            .frame(maxWidth: 80, maxHeight: 80)
                        Circle()
                            .fill(.clear)
                            .strokeBorder()
                            .frame(maxWidth: 160, maxHeight: 160)

                    }
                }

            }
            .onChange(of: selectedItem) {
                Task {  // Incase of multiple selection newValue is of array type
                    if let data = try? await selectedItem?.loadTransferable(type: Image.self) {
                        selectedImage = data
                    }
                }
            }
            TextField("username", text: $username)
                .padding(.leading, 10)
                .frame(minWidth: 80, minHeight: 47)
                .background(.secondary, in: RoundedRectangle(cornerRadius: 10))
            Button(
                action: {
                    if validate(username) {
                        onLoginComplete()
                    }
                },
                label: {
                    Text("Next")
                        .frame(maxWidth: .infinity, minHeight: 47)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                })

        }
        .padding()
        .navigationTitle("Registration")
    }
}

