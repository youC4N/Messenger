import PhotosUI
import SwiftUI

struct ImageDecodeError: Error {}

struct AvatarPhoto: Transferable {
    var contentType: UTType
    var bytes: Data
    var image: Image

    static var transferRepresentation: some TransferRepresentation {
        dataRepr(ofType: .heic)
        dataRepr(ofType: .heif)
        dataRepr(ofType: .jpeg)
        dataRepr(ofType: .png)
    }

    private static func dataRepr(ofType type: UTType) -> DataRepresentation<Self> {
        DataRepresentation(importedContentType: type) { data in
            let image = UIImage(data: data)
            guard let prepared = await image?.byPreparingForDisplay() else {
                throw ImageDecodeError()
            }

            return AvatarPhoto(contentType: type, bytes: data, image: Image(uiImage: prepared))
        }
    }
}

#Preview {
    Registration(token: "nope", onLoginComplete: { _, _ in })
}

struct AvatarSelection: View {
    var selectedImage: Image?

    var body: some View {
        if let selectedImage = selectedImage {
            selectedImage
                .resizable()
                .contentTransition(.opacity)
                .scaledToFill()
        } else {
            ZStack {
                Image(systemName: "person")
                    .resizable()
                    .padding(60)
                Circle()
                    .fill(.clear)
                    .strokeBorder()
            }
        }
    }
}

struct Registration: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: AvatarPhoto? = nil
    @State var username = ""
    var token: String
    var onLoginComplete: (String, Int) -> Void
    func validate(_ name: String) -> Bool {
        if !name.isEmpty {
            return true
        }
        // TODO: validate the code
        return false
    }

    func handleRegistrationClick() {
        guard validate(username) else { return }

        Task {
            let response = await Result {
                try await API.local.registerUser(
                    registrationToken: token,
                    username: username,
                    avatar: selectedImage.flatMap { avatar in
                        avatar.contentType.mimeType.map { mimeType in
                            .init(bytes: avatar.bytes, contentType: mimeType)
                        }
                    })
            }
            switch response {
            case .failure: break // TODO:
            case .success(.invalidToken(reason: _)): break // TODO: send the user back to the phone number screen
            case .success(.success(sessionToken: let sessionToken, userID: let userID)):
                onLoginComplete(sessionToken, userID)
            }
        }
    }

    func handleGallerySelectionChange() {
        logger.info(
            "selected Items \(String(describing: selectedItem?.supportedContentTypes))")

        guard let selectedItem = selectedItem else {
            logger.info("Cleared selected gallery item")
            return
        }

        Task {
            do {
                let mimeTypes = selectedItem.supportedContentTypes.compactMap { $0.preferredMIMEType }.map(\.description)
                logger.info("Selected gallery item: \(String(describing: mimeTypes))")
                guard let data = try await selectedItem.loadTransferable(type: AvatarPhoto.self) else {
                    logger.error("Couldn't find suitable conversion for AvatarPhoto")
                    return
                }
                withAnimation {
                    selectedImage = data
                }
                logger.info("Transferred gallery image into AvatarPhoto \(data.contentType), \(data.bytes)")
            } catch {
                logger.error("While transferring to AvatarPhoto, error occurred: \(error)")
            }
        }
    }

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                preferredItemEncoding: .current,
                photoLibrary: .shared())
            {
                AvatarSelection(selectedImage: selectedImage?.image)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 80, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(Circle())
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
            }
            .onChange(of: selectedItem, handleGallerySelectionChange)
            TextField("username", text: $username)
                .padding(.leading, 10)
                .frame(minWidth: 80, minHeight: 47)
                .background(.secondary, in: RoundedRectangle(cornerRadius: 10))
            Button(action: handleRegistrationClick) {
                Text("Next")
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(
                        .secondary,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding()
        .navigationTitle("Registration")
    }
}
