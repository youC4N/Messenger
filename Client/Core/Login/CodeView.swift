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
    case existingLogin(sessionToken: String, userInfo: [String: String])

    enum CodingKeys: String, CodingKey {
        case type, registrationToken, sessionToken, userInfo, phone
    }

    enum Tag: String, Codable {
        case invalid, expired, registrationRequired = "registration-required", existingLogin =
            "existing-login"
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
            let userInfo = try container.decode([String: String].self, forKey: .userInfo)
            self = .existingLogin(sessionToken: sessionToken, userInfo: userInfo)
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
    var onLoginComplete: () -> Void
    var onRegistrationRequired: (String) -> Void
    let otpToken: String
    func validate(_ code: String) -> Bool {
        // TODO: validate the code
        return true
    }
    
    var body: some View {
        VStack {
            Text("Enter the code")
            HStack {
                ZStack {

                    TextField("", text: $code)
                        .padding(.leading, 10)
                        .frame(maxWidth: 160, minHeight: 47)
                        .background(.secondary, in: RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled(true)
                }
            }

            Button(
                action: {
                    Task {
                        do {
                            let loginResponse: LoginResponse = try await requestLogin(
                                forCode: code, forToken: otpToken)
                            switch loginResponse{
                            case .existingLogin(sessionToken: let a , userInfo: let b):
                                onLoginComplete()
                            case .registrationRequired(registrationToken: let foo, phone: let boo):
                                onRegistrationRequired(foo)
                            default:
                                break
                            }
                        } catch var e {
                            throw e
                        }
                    }
                },
                label: {
                    Text("Next")
                        .frame(maxWidth: .infinity, minHeight: 47)
                        .background(
                            .secondary,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            )
        }
        .padding()
        .navigationTitle("Authorization")
    }

}

enum ServerRequestError: Error, CustomStringConvertible {

    case nonHTTPResponse(got: Any.Type)
    case serverError(status: Int, message: String?)

    var description: String {
        switch self {

        case .nonHTTPResponse(let got):
            return "Recived a non HTTP response of type \(got)"
        case .serverError(let status, let message):
            return
                "Recived a server error with a status: \(status) and body \(message ?? "<binary>")"
        }
    }
}


