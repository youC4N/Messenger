import RawDawg
import Vapor
import MultipartKit
import MessengerInterface

extension RegistrationResponse.Success: Content {}
extension RegistrationResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .invalidToken(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.invalidToken, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .success(let payload):
            try await payload.encodeResponse(for: request)
        }
    }
}

/// Cause Vapor's `File` is a goddamn joke. **Only works for multipart decoding!**
extension FileForUpload<ByteBuffer>: MultipartPartConvertible {
    public var multipart: MultipartPart? {
        MultipartPart(
            headers: ["Content-Type": contentType.description],
            body: bytes
        )
    }
    
    public init?(multipart: MultipartKit.MultipartPart) {
        guard let contentType = multipart.headers.contentType else {
            return nil
        }
        self.init(bytes: multipart.body, contentType: MIMEType(rawValue: contentType.description))
    }
}

@Sendable
func registrationRoute(req: Request) async throws -> RegistrationResponse {
    let registrationRequest = try req.content.decode(RegistrationRequest<ByteBuffer>.self)
    guard
        let regSesh = try await fetchRegistration(
            byToken: registrationRequest.registrationToken,
            in: req.db
        )
    else { return .invalidToken() }
    guard regSesh.expiresAt > Date.now else {
        req.logger.warning("Tried to register a new user with expired token")
        try await deleteRegistrationSession(byToken: registrationRequest.registrationToken, in: req.db)
        return .invalidToken()
    }
    
    let userID = try await createUser(
        username: registrationRequest.username,
        phone: regSesh.phone,
        avatar: registrationRequest.avatar,
        in: req
    )
    req.logger.info(
        "New user registered",
        metadata: [
            "userID": "\(userID)", "name": "\(registrationRequest.username)",
            "phone": "\(regSesh.phone)", "uploadedAvatar": "\(registrationRequest.avatar != nil)"
        ]
    )
    try await deleteRegistrationSession(byToken: registrationRequest.registrationToken, in: req.db)

    let sessionToken = try await createSession(for: userID, in: req)
    return .success(.init(sessionToken: sessionToken, userID: userID))
}

struct RegistrationSession: Decodable {
    var phone: PhoneNumber
    var expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case phone, expiresAt = "expires_at"
    }
}

private func deleteRegistrationSession(byToken token: RegistrationToken, in db: Database) async throws {
    try await withContext("Deleting stale registration session") {
        try await db.prepare("delete from registration_tokens where token=\(token)").run()
    }
}

private func fetchRegistration(byToken token: RegistrationToken, in db: Database) async throws
    -> RegistrationSession?
{
    try await withContext("Retrieving phone given registrationToken") {
        try await db.prepare(
            "select phone, expires_at from registration_tokens where token = \(token)"
        ).fetchOptional()
    }
}

private func createUser(username: String, phone: PhoneNumber, avatar: FileForUpload<ByteBuffer>?, in req: Request) async throws -> UserID {
    req.logger.info("Trying to create user", metadata:
                    ["username": "\(username)",
                     "phone": "\(phone)",
                     "avatarType": "\(avatar?.contentType.rawValue))"])
    return try await withContext("Saving new user") {
        try await req.db.prepare(
            """
            insert into users (first_name, phone_number, avatar, avatar_type)
            values (\(username), \(phone), \(avatar?.bytes), \(avatar?.contentType))
            returning id
            """
        ).fetchOne()
    }
}

extension ByteBuffer: SQLPrimitiveEncodable {
    public func encode() -> RawDawg.SQLiteValue {
        .blob(.loaded(Data(buffer: self)))
    }
}
