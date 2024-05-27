import RawDawg
import Vapor

struct LoginRequest: Content {
    var token: String
    var code: String
}

enum LoginResponse: Encodable, Decodable, Content {
    case invalid
    case expired
    case registrationRequired(registrationToken: String, phone: String)
    case existingLogin(sessionToken: String)

    enum CodingKeys: String, CodingKey {
        //userInfo
        case type, registrationToken, sessionToken, phone
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
        //let userInfo
        case .existingLogin(let sessionToken):
            try container.encode(Tag.existingLogin, forKey: .type)
            try container.encode(sessionToken, forKey: .sessionToken)
        //try container.encode(userInfo, forKey: .userInfo)
        }
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
            //let userInfo = try container.decode([String: String].self, forKey: .userInfo)
            self = .existingLogin(sessionToken: sessionToken)
        }
    }
}

func createSession(for userId: Int, in req: Request) async throws -> String {
    let session = nanoid()
    try await req.db.prepare(
        """
        insert into sessions (session_token, user_id) values (\(session), \(userId))
        """
    ).run()
    return session
}

@Sendable
func loginRoute(req: Request) async throws -> LoginResponse {
    let loginRequest = try req.content.decode(LoginRequest.self)
    let input: (String, String, Date)? = try await req.db.prepare(
        """
        select phone, code, expires_at
        from one_time_passwords
        where token = \(loginRequest.token)
        """
    ).fetchOptional()

    guard let (phone, persistedCode, expiresAt) = input else {
        req.logger.info(
            "There is no entry for the token", metadata: ["token": "\(loginRequest.token)"])
        return .expired
    }

    guard expiresAt < Date.now else {
        try await req.db.prepare(
            "delete from one_time_passwords where token = \(loginRequest.token)"
        ).run()
        req.logger.info(
            "The token expired",
            metadata: ["token": "\(loginRequest.token)", "expires_at": "\(expiresAt)"])
        return .expired
    }

    guard persistedCode == loginRequest.code else {
        req.logger.info(
            "Invalid code for this token",
            metadata: ["token": "\(loginRequest.token)", "code": "\(loginRequest.code)"])
        return .invalid
    }

    try await req.db.prepare("delete from one_time_passwords where token = \(loginRequest.token)")
        .run()
    if try await userExists(byPhone: phone, in: req.db) {
        // TODO: login
        let userID: Int = try await req.db.prepare(
            "select id from users where phone_number = \(phone)"
        ).fetchOptional()!
        let sessionToken = try await createSession(for: userID, in: req)
        req.logger.info("Login successed")
        req.logger.info(
            "Login session created",
            metadata: ["userID": "\(userID)", "sessionToken": "\(sessionToken)"])
        return .existingLogin(sessionToken: sessionToken)
    } else {
        let registrationToken = nanoid()
        try await req.db.prepare(
            """
            insert into registration_tokens (token, phone, expires_at)
            values (\(registrationToken), \(phone), datetime('now', 'subsecond', '+14 days'));
            """
        ).run()
        req.logger.info("registration started")
        return .registrationRequired(registrationToken: registrationToken, phone: phone)
    }

}

// Two hardest things in CS:
// - cache invalidation
// - naming things
// - off by one errors

func userExists(byPhone number: String, in db: Database) async throws -> Bool {
    try await db.prepare("select exists (select 1 from users where phone_number = \(number))")
        .fetchOne()
}
