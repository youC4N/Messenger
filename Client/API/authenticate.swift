import Foundation

private struct LoginRequest: Encodable {
    var code: String
    var token: OTPToken
}

enum LoginResponse: Decodable, Hashable {
    case invalid
    case expired
    case registrationRequired(registrationToken: RegistrationToken, phone: PhoneNumber)
    case existingLogin(sessionToken: SessionToken, userID: UserID)

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
            let phone = try container.decode(PhoneNumber.self, forKey: .phone)
            let registrationToken = try container.decode(RegistrationToken.self, forKey: .registrationToken)
            self = .registrationRequired(registrationToken: registrationToken, phone: phone)
        case .existingLogin:
            let sessionToken = try container.decode(SessionToken.self, forKey: .sessionToken)
            let userID = try container.decode(UserID.self, forKey: .userID)
            self = .existingLogin(sessionToken: sessionToken, userID: userID)
        }
    }
}


extension API {
    func authenticate(forCode code: String, otpToken token: OTPToken) async throws -> LoginResponse {
        API.logger.info("Authenticating with code: \(code, privacy: .private), for token: \(token.description, privacy: .private)")
        
        var request = URLRequest(url: endpoint.appending(component: "login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(code: code, token: token))
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }
        
        API.logger.info("POST /login response: \(httpResponse.statusCode, privacy: .public)")
        guard httpResponse.statusCode == 200 else {
            let error = ServerRequestError(fromResponse: httpResponse, data: body)
            
            API.logger.error("Server error occurred for POST /login \(error, privacy: .public)")
            throw error
        }
        return try JSONDecoder().decode(LoginResponse.self, from: body)
    }
}
