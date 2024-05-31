import RawDawg
import Vapor

// TODO: expiration check
struct RegistrationRequest: Content, Sendable {
    var registrationToken: String
    var username: String
    var avatar: File?
}

struct RegistrationResponse: Content, Sendable {
    var sessionToken: String
}

@Sendable
func registrationRoute(req: Request) async throws -> RegistrationResponse {
    let registrationRequest = try req.content.decode(RegistrationRequest.self)
    guard
        let userPhoneNumber = try await fetchPhoneNumber(
            fromRegistration: registrationRequest.registrationToken,
            in: req.db
        )
    else { throw Abort(.badRequest, reason: "Invalid registration token.") }

    let userID = try await createUser(
        username: registrationRequest.username,
        phone: userPhoneNumber,
        avatar: registrationRequest.avatar,
        in: req.db
    )
    req.logger.info(
        "New user registered",
        metadata: [
            "userID": "\(userID)", "name": "\(registrationRequest.username)",
            "phone": "\(userPhoneNumber)",
        ]
    )

    let sessionToken = try await createSession(for: userID, in: req)
    return RegistrationResponse(sessionToken: sessionToken)
}

private func fetchPhoneNumber(fromRegistration token: String, in db: Database) async throws
    -> String?
{
    try await withContext("Retrieving phone given registrationToken") {
        try await db.prepare(
            "select phone from registration_tokens where token = \(token)"
        ).fetchOptional()
    }
}

private func createUser(username: String, phone: String, avatar: File?, in db: Database) async throws -> Int {
    try await withContext("Saving new user") {
        try await db.prepare(
            """
            insert into users (first_name, phone_number, avatar, avatar_type)
            values (\(username), \(phone), \(avatar?.data), \(avatar?.contentType))
            returning id
            """
        ).fetchOne()
    }
}

extension HTTPMediaType: SQLPrimitiveDecodable, SQLPrimitiveEncodable {
    /// Yoinked verbatim implementation from the Vapor's internal `HTTPMediaType` init
    init?(parse headerValue: String) {
        let directives = headerValue.components(separatedBy: [",", ";"])
        guard let value = directives.first else {
            /// not a valid header value
            return nil
        }

        /// parse out type and subtype
        let typeParts = value.split(separator: "/", maxSplits: 2)
        guard typeParts.count == 2 else {
            /// the type was not form `foo/bar`
            return nil
        }

        self.init(
            type: String(typeParts[0]).trimmingCharacters(in: .whitespaces),
            subType: String(typeParts[1]).trimmingCharacters(in: .whitespaces)
        )
    }
    
    public init?(fromSQL primitive: SQLiteValue) {
        guard case .text(let string) = primitive else {
            return nil
        }
        self.init(parse: string)
    }

    public func encode() -> SQLiteValue {
        .text(self.serialize())
    }
}

extension ByteBuffer: SQLPrimitiveEncodable {
    public func encode() -> RawDawg.SQLiteValue {
        .blob(.loaded(Data(buffer: self)))
    }
}
