import Foundation
import RawDawg
import Vapor
import MessengerInterface

extension User: Content {}
extension FindUserResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .unauthorized:
            try await ErrorResponse(Self.ErrorKind.unauthorized, reason: "Unauthorized.")
                .encodeResponse(status: .unauthorized, for: request)
        case .absent:
            try await ErrorResponse(Self.ErrorKind.absent, reason: "Can't find user with specified phone")
                .encodeResponse(status: .unauthorized, for: request)
        case .invalidPhoneNumber(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.invalidPhoneNumber, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .found(let payload):
            try await payload.encodeResponse(for: request)
        }
    }
}

@Sendable
func findUserRoute(req: Request) async throws -> FindUserResponse {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        return .unauthorized
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        return .unauthorized
    }
    
    guard let number: String = try req.query.get(at: "phone") else {
        throw Abort(.badRequest, reason: "Missing phone query parameter.")
    }
    guard let normNumber = PhoneNumber(rawValue: number) else {
        return .invalidPhoneNumber()
    }

    let userInfo: (UserID, String)? = try await req.db.prepare(
        "select id, first_name from users where phone_number = \(normNumber)")
        .fetchOptional()

    guard let (userID, username) = userInfo else {
        req.logger.info("There is no such number in db", metadata: ["number": "\(normNumber)"])
        return .absent
    }
    req.logger.info("Retrieved user info", metadata: ["username": "\(username)", "userID": "\(userID)", "phone": "\(number)"])

    return .found(.init(id: userID, username: username))
}

func sessionTokenExists(token: String, in db: Database) async throws -> Bool {
    try await db.prepare(
        "select exists (select 1 from sessions where session_token = \(token))")
        .fetchOne()
}
