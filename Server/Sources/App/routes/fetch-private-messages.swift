import MessengerInterface
import RawDawg
import Vapor

extension MYMessage: Content {
}

extension FetchPrivateMessagesResponse: AsyncResponseEncodable {
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
func fetchPrivateMessagesRoute(req: Request) async throws -> FetchPrivateMessagesResponse {
//    guard let sessionToken = req.headers.bearerAuthorization?.token else {
//        return .unauthorized
//    }
    guard let sessionToken: String = req.query[String.self, at: "sessionToken"] else {
        return .unauthorized
    }
    guard let authorID = try await sessionUser(from: SessionToken(rawValue: sessionToken), in: req.db) else {
        return .unauthorized
    }
    guard let idB: Int = req.parameters.get("idB") else {
        throw Abort(.badRequest, reason: "Can't get parameter idB")
    }

    let participantAID = min(authorID.rawValue, idB)
    let participantBID = max(authorID.rawValue, idB)
    let rows: [(Int, Date)]

    guard
        let chatID: Int = try await req.db.prepare(
            """
            select id from private_chats
            where participant_a_id = \(participantAID)
            and participant_b_id = \(participantBID)
            """
        ).fetchOptional()
    else {
        throw Abort(
            .badRequest,
            reason:
                "Can't find the chat for participants A: \(participantAID), B: \(participantBID)")
    }
    do {
        rows = try await req.db.prepare(
            """
            select id, created_at from private_messages
            where chat_id = \(chatID)
            order by message_order DESC
            """
        ).fetchAll()
    }
    catch {
        return .success([])
    }
    return .success(
        rows.map{ (messageID, sentAt) in
            MYMessage(id: MessageID(rawValue: messageID), author: authorID)
        })
}
