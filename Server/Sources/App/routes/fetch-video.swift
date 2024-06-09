import Foundation
import MessengerInterface
import NIOFileSystem
import SystemPackage
import Vapor

private struct QueryParams: Decodable {
    var sessionToken: SessionToken
}

@Sendable
func fetchVideoRoute(req: Request) async throws -> Response {
    let query = try req.query.decode(QueryParams.self)
    guard var userAID = try await sessionUser(from: query.sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Unauthorized.")
    }
    guard var userBID: UserID = req.parameters.get("otherParticipantID") else {
        throw Abort(.badRequest, reason: "otherParticipantID path parameter is not supplied.")
    }
    guard let messageID: MessageID = req.parameters.get("messageID") else {
        throw Abort(.badRequest, reason: "messageID path parameter is not supplied.")
    }
    guard userAID != userBID else {
        throw Abort(.badRequest, reason: "Chats with oneself are prohibited.")
    }

    if userAID > userBID {
        swap(&userAID, &userBID)
    }

    let upload: (FilePath, Int?)? = try await req.db.prepare("""
        select video_uploads.file_path, video_uploads.file_size
        from private_chats
        join private_messages
          on private_chats.id = private_messages.chat_id
        join video_uploads
          on video_uploads.id = private_messages.upload_id
        where participant_a_id = \(userAID)
          and participant_b_id = \(userBID)
          and private_messages.id = \(messageID)
        """
    ).fetchOptional()

    guard let (path, fileSize) = upload else {
        throw Abort(.notFound, reason: "No such message.")
    }

    let body = Response.Body(managedAsyncStream: { writer in
        var bytes = 0
        try await FileSystem.shared.withFileHandle(forReadingAt: path) { file in
            for try await chunk in file.readChunks() {
                try await writer.write(.buffer(chunk))
                bytes += chunk.readableBytesView.count
                req.logger.debug("Sent video chunk of size \(chunk.readableBytesView.count)")
            }
        }
        req.logger.info("Sent video stream of \(bytes) bytes", metadata: ["messageID": "\(messageID)"])
    }, count: fileSize ?? -1)
    return Response(status: .ok, headers: ["Content-Type": "video/quicktime"], body: body)
}
