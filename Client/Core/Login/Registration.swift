import PhotosUI
import SwiftUI


struct RegistrationRequest: Encodable {
    var registrationToken: String
    var username: String
//    var image: Data?
}

struct RegistrationResponse: Decodable {
    var sessionToken: String
}

struct ImageDecodeError: Error { }

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
    Registration(token: "nope", onLoginComplete: {})
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
    var onLoginComplete: () -> Void
    func validate(_ name: String) -> Bool {
        if !name.isEmpty{
            return true
        }
        // TODO: validate the code
        return false
    }

    func requestRegistration(
        forRegToken token: String,
        forUsername username: String
    ) async throws -> RegistrationResponse {
        let address = "http://127.0.0.1:8080/registration"
        let url = URL(string: address)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RegistrationRequest(registrationToken: token, username: username))
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
        }
        logger.info("registration status code -- \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            throw ServerRequestError.serverError(
                status: httpResponse.statusCode,
                message: String(data: body, encoding: .utf8)
            )
        }
        return try JSONDecoder().decode(RegistrationResponse.self, from: body)
    }

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            ) {
                AvatarSelection(selectedImage: selectedImage?.image)
                    .frame(minWidth: 80, maxWidth: .infinity, minHeight: 80, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(Circle())
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
            }
            .onChange(of: selectedItem) {
                Task {  // Incase of multiple selection newValue is of array type
                    do {
                        guard let selectedItem = selectedItem else {
                            logger.info("Cleared selected gallery item")
                            return
                        }
                        let mimeTypes = selectedItem.supportedContentTypes.compactMap { $0.preferredMIMEType }.map(\.description)
                        logger.info("Selected gallery item: \(String(describing: mimeTypes))")
                        if let data = try await selectedItem.loadTransferable(type: AvatarPhoto.self) {
                            withAnimation {
                                selectedImage = data
                            }
                            logger.info("Transferred gallery image into AvatarPhoto \(data.contentType), \(data.bytes)")
                        }
                    } catch {
                        logger.error("While transferring to AvatarPhoto, error occurred: \(error)")
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
                        Task{
                            do{
                                _ = try await requestRegistration(forRegToken: token, forUsername: username)
                            }
                        }
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


