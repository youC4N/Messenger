import RawDawg
import Vapor


@Sendable
func createNewChat(for req: Request) async throws -> Response {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    guard let initialUser: Int = try await req.db.prepare("select user_id from sessions where session_token = \(sessionToken)").fetchOptional() else {
        throw Abort(.unauthorized, reason: "Can't find user for session.")
    }
    guard let secondUser: Int = req.parameters.get("idB") else {
        throw Abort(.badRequest, reason: "Can't get idB parameter from request.")
    }
    let participant_a = min(initialUser, secondUser)
    let participant_b = max(initialUser, secondUser)
    
    do {
        try await req.db.prepare(
        """
        insert into
            private_chats(participant_a_id, participant_b_id, message_count)
            values(\(participant_a), \(participant_b), '0')
        """).run()
    } catch {
        throw Abort(.internalServerError, reason: "Couldn't insert new chat for ids: a = \(participant_a), b = \(participant_b)")
    }
    
    
    return Response(status: .ok)
}
