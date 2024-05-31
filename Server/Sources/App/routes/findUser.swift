import Foundation
import RawDawg
import Vapor

struct FindUserResponse: Content {
    var username: String
    var id: Int
}

@Sendable
func findUserRoute(req: Request) async throws -> FindUserResponse {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    
    guard let number = req.parameters.get("phone") else {
        throw Abort(.internalServerError, reason: "Missing phone path parameter.")
    }
    let normNumber = try normalisedPhoneNumber(for: number)

    req.logger.info("Successfully parsed", metadata: ["number": "\(number)", "sessionToken": "\(sessionToken)"])
    let userInfo: (Int, String)? = try await req.db.prepare(
        "select id, first_name from users where phone_number = \(normNumber)")
        .fetchOptional()

    guard let (userID, username) = userInfo else {
        req.logger.info("There is no such number in db", metadata: ["number": "\(normNumber)"])
        throw Abort(.notFound, reason: "Phone number isn't associated with the user.")
    }
    req.logger.info("Retrieved user info", metadata: ["username": "\(username)", "userID": "\(userID)", "phone": "\(number)"])

    return FindUserResponse(username: username, id: userID)
}

func sessionTokenExists(token: String, in db: Database) async throws -> Bool {
    try await db.prepare(
        "select exists (select 1 from sessions where session_token = \(token))")
        .fetchOne()
}
