import OSLog
import SwiftUI

struct LoginRequest: Encodable {
    var code: String
    var token: String
}

enum LoginResponse: Decodable, Hashable {
    case invalid
    case expired
    case registrationRequired(registrationToken: String, phone: String)
    case existingLogin(sessionToken: String, userID: Int)

    enum CodingKeys: String, CodingKey {
        case type, registrationToken, sessionToken, phone, userID
    }

    enum Tag: String, Codable {
        case invalid, expired, registrationRequired = "registration-required", existingLogin = "existing-login"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Tag.self, forKey: .type) {
        case .invalid:
            self = .invalid
        case .expired:
            self = .expired
        case .registrationRequired:
            let phone = try container.decode(String.self, forKey: .phone)
            let registrationToken = try container.decode(String.self, forKey: .registrationToken)
            self = .registrationRequired(registrationToken: registrationToken, phone: phone)
        case .existingLogin:
            let sessionToken = try container.decode(String.self, forKey: .sessionToken)
            let userID = try container.decode(Int.self, forKey: .userID)
            self = .existingLogin(sessionToken: sessionToken, userID: userID)
        }
    }
}

func requestLogin(forCode code: String, forToken token: String) async throws -> LoginResponse {
    let address = "http://127.0.0.1:8080/login"
    let url = URL(string: address)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(LoginRequest(code: code, token: token))
    let response = try await URLSession.shared.data(for: request)
    guard let httpResponse = response.1 as? HTTPURLResponse else {
        throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
    }

    print("\(httpResponse.statusCode)")
    guard httpResponse.statusCode == 200 else {
        throw ServerRequestError.serverError(
            status: httpResponse.statusCode,
            message: String(data: response.0, encoding: .utf8)
        )
    }
    return try JSONDecoder().decode(LoginResponse.self, from: response.0)
}

struct CodeView: View {
    @State var code = ""
    @State var response: LoginResponse?
    @State var errorMessage: String?
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertAction: (() -> Void)? = nil
    var onLoginComplete: (String, Int) -> Void
    var onExpired: () -> Void
    var onRegistrationRequired: (String) -> Void
    let otpToken: String

    func validate(_ code: String) -> Bool {
        // TODO: validate the code
        return true
    }

    func handleResponse(_ response: LoginResponse) {
        switch response {
        case .expired:
            alertMessage = "The code has expired. Please request a new one."
            alertAction = { onExpired() }
            showAlert = true
        case .existingLogin(sessionToken: let token, userID: let userID):
            onLoginComplete(token, userID)
        case .registrationRequired(registrationToken: let registrationToken, phone: _):
            onRegistrationRequired(registrationToken)
        case .invalid:
            alertMessage = "The code you entered is invalid. Please try again."
            showAlert = true
        }
    }

    var body: some View {
        VStack {
            Text("Enter the code")
            HStack {
                ZStack {
                    TextField("", text: $code)
                        .padding(.leading, 10)
                        .frame(maxWidth: 160, minHeight: 47)
                        .background(Color.secondary, in: RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled(true)
                }
            }

            Button(
                action: {
                    Task {
                        do {
                            let response = try await requestLogin(forCode: code, forToken: otpToken)
                            handleResponse(response)
                            
                        } catch {
                            errorMessage = error.localizedDescription
                            alertMessage = "An error occurred: \(errorMessage ?? "Unknown error")"
                            showAlert = true
                        }
                    }
                },
                label: {
                    Text("Next")
                        .frame(maxWidth: .infinity, minHeight: 47)
                        .background(
                            Color.secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            )

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Authorization")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if let action = alertAction {
                        action()
                    }
                }
            )
        }
    }
}

enum ServerRequestError: Error, CustomStringConvertible {
    case nonHTTPResponse(got: Any.Type)
    case serverError(status: Int, message: String?)

    var description: String {
        switch self {
        case .nonHTTPResponse(let got):
            return "Received a non-HTTP response of type \(got)"
        case .serverError(let status, let message):
            return "Received a server error with a status: \(status) and body \(message ?? "<binary>")"
        }
    }
}
