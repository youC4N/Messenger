import Vapor
import RawDawg


// TODO: expiration check
struct RegistrationRequest: Content, Sendable {
    var registrationToken: String
    var username: String
//    var image: Data?
}

struct RegistrationResponse: Content, Sendable {
    var sessionToken: String
}

@Sendable
func registrationRoute(req: Request) async throws -> RegistrationResponse {
    let registrationRequest = try req.content.decode(RegistrationRequest.self)
    guard let userPhoneNumber = try await fetchPhoneNumber(fromRegistration: registrationRequest.registrationToken, in: req.db)
    else { throw Abort(.badRequest, reason: "Invalid registration token.") }
    
    // TODO: take and save Avatar for every user
    let userID: Int = try await createUser(username: registrationRequest.username, phone: userPhoneNumber, in: req.db)
    req.logger.info(
        "New user registered",
        metadata: ["userID": "\(userID)", "name": "\(registrationRequest.username)", "phone": "\(userPhoneNumber)"]
    )

    let sessionToken = try await createSession(for: userID, in: req)
    return RegistrationResponse(sessionToken: sessionToken)
}

private func fetchPhoneNumber(fromRegistration token: String, in db: Database) async throws -> String? {
    try await withContext("Retrieving phone given registrationToken") {
        try await db.prepare(
            "select phone from registration_tokens where token = \(token)"
        ).fetchOptional()
    }
}

private func createUser(username: String, phone: String, in db: Database) async throws -> Int {
    try await withContext("Saving new user") {
        try await db.prepare(
            """
            insert into users (first_name, phone_number)
            values (\(username), \(phone))
            returning id
            """
        ).fetchOne()
    }
}
