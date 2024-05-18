import SwiftUI
import Vapor
import RawDawg

struct LoginRequest: Content {
    var token: String
    var code: String
}

enum LoginResponse: Encodable,  Content {
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

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)  // { type: , registrationToken: , sessionToken: , userInfo: }
        switch self {
        case .invalid:
            try container.encode(Tag.invalid, forKey: .type)  // { type: "invalid" }
        case .expired:
            try container.encode(Tag.expired, forKey: .type)  // { type: "expired" }
        case .registrationRequired(let registrationToken, let userPhone):
            try container.encode(Tag.registrationRequired, forKey: .type)
            try container.encode(registrationToken, forKey: .registrationToken)
            try container.encode(userPhone, forKey: .phone)
        case .existingLogin(let sessionToken, let userInfo):
            try container.encode(Tag.existingLogin, forKey: .type)
            try container.encode(sessionToken, forKey: .sessionToken)
            try container.encode(userInfo, forKey: .userInfo)
        }
    }

//    init(from decoder: any Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        switch try container.decode(Tag.self, forKey: .type) {
//        case .invalid:
//            self = .invalid
//        case .expired:
//            self = .expired
//        case .registrationRequired:
//            let registrationToken = try container.decode(String.self, forKey: .registrationToken)
//            self = .registrationRequired(registrationToken: registrationToken)
//        case .existingLogin:
//            let sessionToken = try container.decode(String.self, forKey: .sessionToken)
//            let userInfo = try container.decode([String: String].self, forKey: .userInfo)
//            self = .existingLogin(sessionToken: sessionToken, userInfo: userInfo)
//        }
//    }
}

func loginRoute(req: Request) async throws -> LoginResponse {
    let loginRequest = try req.content.decode(LoginRequest.self)
    let input: PersistedOTP? = try await req.db.prepare(
        """
        select phone, code, expires_at
        from one_time_passwords
        where token = \(loginRequest.token)
        """
    ).fetchOptional()
    
    guard let input = input else {
        return .expired
    }

    guard input.expires_at > Date.now else {
        // TODO: Remove expired token
        return .expired
    }
    
    guard input.code == loginRequest.code else {
        return .invalid
    }
    
    // TODO: Expire otp_token
    
    if try await userExists(byPhone: input.phone, in: req.db) {
        // TODO: login
        let O = "O"
        let o = "o"
        return .existingLogin(sessionToken: "", userInfo: [O:o])
    } else {
        let registrationToken = nanoid()
        // TODO: insert in registration_tokens new token
        return .registrationRequired(registrationToken: registrationToken, phone: input.phone)
    }

}

// Two hardest things in CS:
// - cache invalidation
// - naming things
// - off by one errors

func userExists(byPhone number: String, in db: Database) async throws -> Bool {
    try await db.prepare("select exists (select 1 from users where number = \(number))").fetchOne()
}


struct PersistedOTP: Decodable {
    var phone: String
    var code: String
    var expires_at: Date
}
