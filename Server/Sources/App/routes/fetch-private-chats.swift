import RawDawg
import Vapor

struct User: Content {
    var id: Int
    var username: String
}

@Sendable 
func fetchPrivateChatsRoute(req: Request) async throws -> [User] {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    guard let userID = try await sessionUser(from: sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }

    let rows: [(Int, String, Int, String)] = try await req.db.prepare(
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
    
    return rows.map { (aID, aUsername, bID, bUsername) in
        if userID == aID {
            User(id: bID, username: bUsername)
        } else {
            User(id: aID, username: aUsername)
        }
    }
}

func sessionUser(from token: String, in db: Database) async throws -> Int? {
    try await db.prepare("select user_id from sessions where session_token=\(token)").fetchOptional()
}
