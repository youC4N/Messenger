import RawDawg
import Vapor
import MessengerInterface

extension LoginResponse.Success: Content {}
extension LoginResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        return switch self {
        case .invalid(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.invalid, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .expired(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.expired, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .success(let payload):
            try await payload.encodeResponse(for: request)
        }
    }
}

@Sendable
func loginRoute(req: Request) async throws -> LoginResponse {
    let loginRequest = try req.content.decode(LoginRequest.self)
    let input: (PhoneNumber, String, Date)? =
        try await withContext("Fetching persisted otp values given token") {
            try await req.db.prepare(
                "select phone, code, expires_at from one_time_passwords where token = \(loginRequest.token)"
            ).fetchOptional()
        }

    guard let (phone, persistedCode, expiresAt) = input else {
        req.logger.info(
            "There is no entry for the token", metadata: ["token": "\(loginRequest.token)"]
        )
        return .expired()
    }

    guard expiresAt < Date.now else {
        try await deleteOTP(token: loginRequest.token, in: req.db)
        req.logger.info(
            "Token expired",
            metadata: ["token": "\(loginRequest.token)", "expires_at": "\(expiresAt)"]
        )
        return .expired()
    }

    guard persistedCode == loginRequest.code else {
        req.logger.info(
            "Invalid code for this token",
            metadata: ["token": "\(loginRequest.token)", "code": "\(loginRequest.code)"]
        )
        return .invalid()
    }

    try await deleteOTP(token: loginRequest.token, in: req.db)
    if let userID = try await fetchUserID(byPhone: phone, in: req.db) {
        let sessionToken = try await createSession(for: userID, in: req)
        req.logger.info("Login successed", metadata: ["userID": "\(userID)"])
        return .success(.existingLogin(sessionToken: sessionToken, userID: userID))
    } else {
        let registrationToken = RegistrationToken(rawValue: nanoid())
        try await createRegistrationSession(token: registrationToken, phone: phone, in: req.db)
        req.logger.info("Registration session created")
        return .success(.registrationRequired(registrationToken: registrationToken, phone: phone))
    }
}

// Two hardest things in CS:
// - cache invalidation
// - naming things
// - off by one errors

func createSession(for userId: UserID, in req: Request) async throws -> SessionToken {
    let session = nanoid()
    try await withContext("Saving new session") {
        try await req.db.prepare(
            "insert into sessions (session_token, user_id) values (\(session), \(userId))"
        ).run()
    }
    return SessionToken(rawValue: session)
}

func deleteOTP(token: OTPToken, in db: Database) async throws {
    try await withContext("Deleting OTP given token") {
        try await db.prepare(
            "delete from one_time_passwords where token = \(token)"
        ).run()
    }
}

func fetchUserID(byPhone phone: PhoneNumber, in db: Database) async throws -> UserID? {
    try await withContext("Retriving user id given phone number") {
        try await db.prepare(
            "select id from users where phone_number = \(phone)"
        ).fetchOptional()
    }
}

func createRegistrationSession(token: RegistrationToken, phone: PhoneNumber, in db: Database) async throws {
    try await withContext("Saving registration token") {
        try await db.prepare(
            """
            insert into registration_tokens (token, phone, expires_at)
            values (\(token), \(phone), datetime('now', 'subsecond', '+14 days'));
            """
        ).run()
    }
}
