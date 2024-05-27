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

struct Registration: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
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
                        Task{
                            do{
                                let response = try await requestRegistration(forRegToken: token, forUsername: username)
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


