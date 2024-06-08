import Foundation
import MessengerInterface
import NIOFileSystem
import RawDawg
import SystemPackage
import Vapor

extension Message: Content {}
extension NewMessageResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .unauthorized:
            try await ErrorResponse(Self.ErrorKind.unauthorized, reason: "Unauthorized.")
                .encodeResponse(status: .unauthorized, for: request)
        case .invalidRecipient(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.invalidRecipient, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .unsupportedMediaFormat(reason: let reason):
            try await ErrorResponse(Self.ErrorKind.unsupportedMediaFormat, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .success(let payload):
            try await payload.encodeResponse(for: request)
        }
    }
}

extension FilePath: SQLPrimitiveEncodable {
    public func encode() -> SQLiteValue {
        if let str = String(validating: self) {
            return .text(str)
        } else {
            let data = self.withPlatformString { ptr in
                Data(bytes: ptr, count: strlen(ptr))
            }
            return .blob(.loaded(data))
        }
    }
}

extension FilePath: SQLPrimitiveDecodable {
    public init?(fromSQL primitive: SQLiteValue) {
        switch primitive {
        case .text(let string):
            self.init(string)
        case .blob(.loaded(let data)):
            self = data.withUnsafeBytes { (buf: UnsafeRawBufferPointer) -> Self in
                let charbuf = buf.assumingMemoryBound(to: CInterop.Char.self)
                return Self(platformString: charbuf.baseAddress!)
            }
        default:
            return nil
        }
    }
}

extension HTTPMediaType {
    static let hevcVideo = HTTPMediaType(type: "video", subType: "mp4", parameters: ["codecs": "dvhe"])
}

@Sendable
func createNewMessageRoute(for req: Request) async throws -> NewMessageResponse {
    guard req.headers.contentType == .hevcVideo else {
        return .unsupportedMediaFormat(reason: "Unexpected file Content-Type. Only \"video/mp4; codecs=dvhe\" video streams are allowed.")
    }
    guard let sessionToken = req.headers.bearerAuthorization?.token else {
        return .unauthorized
    }
    guard let authorID = try await sessionUser(from: sessionToken, in: req.db) else {
        return .unauthorized
    }
    guard let userBID: UserID = req.parameters.get("idB") else {
        req.logger.error("createNewMessageRoute doesn't have :idB path parameter")
        throw Abort(.badRequest)
    }

    if authorID == userBID {
        return .invalidRecipient(reason: "Cannot create chats with oneself")
    }
    let chatID = try await upsertChat(authorID, userBID, in: req.db)

    let fileName = nanoid() + ".mp4"
    let parentDir = req.videoStorageDirectory
        .appending("private-chat")
        .appending(String(chatID))

    let filePath = parentDir
        .appending(fileName)

    try await FileSystem.shared.createDirectory(at: parentDir, withIntermediateDirectories: true)

    let uploadID: UploadID = try await req.db.prepare("""
        insert into video_uploads(file_path)
        values (\(filePath))
        returning id
        """)
        .fetchOne()
    req.logger.info("Created an entry for video upload at \(filePath)", metadata: ["uploadID": "\(uploadID)"])

    var streamLength = 0
    try await FileSystem.shared.withFileHandle(forWritingAt: filePath, options: .newFile(replaceExisting: false)) { file in
        try await file.withBufferedWriter { writer in
            for try await chunk in req.body {
                streamLength += chunk.readableBytesView.count
                try await writer.write(contentsOf: chunk.readableBytesView)
            }
        }
    }
    
    req.logger.info("Written video stream to \(filePath)", metadata: ["streamLength": "\(streamLength)"])
    
    let lastMessageOrder: Int = try await req.db.prepare("""
        select private_messages.message_order
        from private_chats
        join private_messages
            on private_chats.last_message_id = private_messages.id
        where private_chats.id = \(chatID)
        """)
        .fetchOptional() ?? 0
    let (messageID, sentAt): (MessageID, Date) = try await req.db.prepare("""
        insert into private_messages (chat_id, message_order, upload_id, author_id)
        values (\(chatID), \(lastMessageOrder + 1), \(uploadID), \(authorID)
        returning id
        """).fetchOne()
    
    req.logger.info("Added message to the chat", metadata: ["messageID": "\(messageID)", "chatID": "\(chatID)", "uploadID": "\(uploadID)"])

    return .success(.init(id: messageID, sentAt: sentAt, author: authorID))
}

struct ChatID: IntegralNewtype, SQLNewtype {
    typealias IntegerLiteralType = Int
    var rawValue: Int
}

struct UploadID: IntegralNewtype, SQLNewtype {
    typealias IntegerLiteralType = Int
    var rawValue: Int
}

private func upsertChat(_ aID: UserID, _ bID: UserID, in db: Database) async throws -> ChatID {
    assert(aID != bID, "Cannot create chats when a participant is the same as b participant")
    guard aID < bID else {
        return try await upsertChat(bID, aID, in: db)
    }

    return try await withContext("Fetching existing / creating new chat") {
        let existingChatID: ChatID? = try await db.prepare("""
        select id from private_chats
        where participant_a_id = \(aID) and participant_b_id = \(bID)
        """)
        .fetchOptional()
        if let existingChatID {
            return existingChatID
        }
        return try await db.prepare("""
        insert into private_chats(participant_a_id, participant_b_id)
        values (\(aID), \(bID))
        returning id
        """)
        .fetchOne()
    }
}
