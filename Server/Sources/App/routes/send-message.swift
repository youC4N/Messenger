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
func sendMessageRoute(for req: Request) async throws -> NewMessageResponse {
    guard req.headers.contentType == .hevcVideo else {
        return .unsupportedMediaFormat(reason: "Unexpected file Content-Type. Only \"video/mp4; codecs=dvhe\" video streams are allowed.")
    }
    guard let sessionToken = req.headers.bearerAuthorization else {
        return .unauthorized
    }
    guard let authorID = try await sessionUser(from: sessionToken, in: req.db) else {
        return .unauthorized
    }
    guard let userBID: UserID = req.parameters.get("otherParticipantID") else {
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

    do {
        try await FileSystem.shared.createDirectory(at: parentDir, withIntermediateDirectories: true)
        req.logger.info("Created \(parentDir) directory")
    } catch let fsError as FileSystemError where fsError.code == .fileAlreadyExists {
        req.logger.trace("\(parentDir) already exists")
    }

    let upload = try await persistUpload(stream: req.body, into: filePath, keepTrackIn: req.db, logger: req.logger)

    let message = try await withUploadCleanup(upload: upload, in: req.db, logger: req.logger) {
        try await withFileCleanup(filePath) {
            try await createMessage(in: chatID, authoredBy: authorID, withUpload: upload.id, in: req.db)
        }
    }

    req.logger.info("Added message to the chat", metadata: ["message": "\(message)", "chatID": "\(chatID)", "upload": "\(upload)"])

    return .success(message)
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
            """
        ).fetchOptional()
        if let existingChatID {
            return existingChatID
        }
        return try await db.prepare("""
            insert into private_chats(participant_a_id, participant_b_id)
            values (\(aID), \(bID))
            returning id
            """
        ).fetchOne()
    }
}

private func createMessage(in chat: ChatID, authoredBy author: UserID, withUpload upload: UploadID, in db: Database) async throws -> Message {
    try await withContext("Inserting new message into chat \(chat)") {
        let lastMessageOrder: Int = try await db.prepare("""
            select private_messages.message_order
            from private_chats
            join private_messages
                on private_chats.last_message_id = private_messages.id
            where private_chats.id = \(chat)
            """
        )
        .fetchOptional() ?? 0
        let (id, sentAt): (MessageID, Date) = try await db.prepare("""
            insert into private_messages (chat_id, message_order, upload_id, author_id)
            values (\(chat), \(lastMessageOrder + 1), \(upload), \(author))
            returning id, created_at
            """
        ).fetchOne()
        try await db.prepare("update private_chats set last_message_id = \(id) where id = \(chat)").run()

        return Message(id: id, sentAt: sentAt, author: author)
    }
}

private func persistUpload(stream: Request.Body, into filePath: FilePath, keepTrackIn db: Database, logger: Logger) async throws -> Upload {
    let (uploadID, createdAt): (UploadID, Date) = try await db.prepare("""
        insert into video_uploads(file_path)
        values (\(filePath))
        returning id, created_at
        """
    ).fetchOne()
    let upload = Upload(id: uploadID, path: filePath, createdAt: createdAt)
    logger.info("Created an entry for video upload at \(filePath)", metadata: ["uploadID": "\(upload.id)"])

    let streamLength = try await withUploadCleanup(upload: upload, in: db, logger: logger) {
        try await FileSystem.shared.withFileHandle(forWritingAt: filePath, options: .newFile(replaceExisting: false)) { file in
            try await withFileCleanup(filePath) {
                let streamLength = try await collectStream(into: file, atPath: filePath, stream: stream)
                
                try await db.prepare("update video_uploads set file_size = \(streamLength) where id = \(uploadID)").run()
                
                return streamLength
            }
        }
    }

    logger.info("Written video stream to \(filePath)", metadata: ["streamLength": "\(streamLength)"])

    return upload
}

struct Upload {
    var id: UploadID
    var path: FilePath
    var createdAt: Date
}

private func withUploadCleanup<T>(upload: Upload, in db: Database, logger: Logger, block: () async throws -> T) async throws -> T {
    do {
        return try await block()
    } catch StreamCollectionError.failedFileCleanup(after: let writeError, cause: let cleanupError) {
        logger.error("Error writing to file \(writeError). File cleanup failed \(cleanupError). File is potentially still present. Not touching the upload. Try GC later.")
        throw StreamCollectionError.failedFileCleanup(after: writeError, cause: cleanupError)
    } catch let cause {
        logger.error("Failed to persist stream. File either was successfully removed removing upload, or never created in the first place. Cause: \(cause)", metadata: ["upload": "\(upload)"])
        try await db.prepare("delete from video_uploads where id = \(upload.id)").run()
        throw cause
    }
}

private func withFileCleanup<T>(_ filePath: FilePath, block: () async throws -> T) async throws -> T {
    do {
        return try await block()
    } catch let writeError {
        do {
            try await FileSystem.shared.removeItem(at: filePath)
        } catch let cleanupError {
            throw StreamCollectionError.failedFileCleanup(after: writeError, cause: cleanupError)
        }
        throw StreamCollectionError.failedFileWrite(writeError)
    }
}

private func collectStream(into file: WriteFileHandle, atPath filePath: FilePath, stream: Request.Body) async throws -> Int {
    var streamLength = 0

    try await file.withBufferedWriter { writer in
        for try await chunk in stream {
            streamLength += chunk.readableBytesView.count
            try await writer.write(contentsOf: chunk.readableBytesView)
        }
    }

    return streamLength
}

enum StreamCollectionError: Error {
    case failedFileWrite(any Error)
    case failedFileCleanup(after: any Error, cause: any Error)
}

extension Result where Failure == any Error {
    init(asyncCatching block: () async throws -> Success) async {
        do {
            self = try .success(await block())
        } catch {
            self = .failure(error)
        }
    }
}
