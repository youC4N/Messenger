import MessengerInterface
import RawDawg
import Vapor

extension FetchPrivateChatsResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .unauthorized:
            try await unauthorizedResponse(for: request)
        case .success(let payload):
            try await payload.encodeResponse(for: request)
        }
    }
}

@Sendable
func fetchPrivateChatsRoute(req: Request) async throws -> FetchPrivateChatsResponse {
    guard let sessionToken = req.headers.bearerAuthorization else {
        return .unauthorized
    }
    guard let userID = try await sessionUser(from: sessionToken, in: req.db) else {
        return .unauthorized
    }

    let rows: [(UserID, String, UserID, String)] = try await req.db.prepare(
        """
        select 
            participant_a_id,
            user_a.first_name,
            participant_b_id,
            user_b.first_name
        from private_chats
        inner join users user_a
            on user_a.id = participant_a_id
        inner join users user_b
            on user_b.id = participant_b_id
        where participant_a_id = \(userID) or participant_b_id = \(userID)
        """
    ).fetchAll()

    return .success(
        rows.map { (aID, aUsername, bID, bUsername) in
            if userID == aID {
                User(id: bID, username: bUsername)
            } else {
                User(id: aID, username: aUsername)
            }
        })
}

func sessionUser(from token: SessionToken, in db: SharedConnection) async throws -> UserID? {
    try await db.prepare("select user_id from sessions where session_token=\(token)")
        .fetchOptional()
}
func sessionUser(from token: BearerAuthorization, in db: SharedConnection) async throws -> UserID? {
    try await sessionUser(from: SessionToken(rawValue: token.token), in: db)
}
