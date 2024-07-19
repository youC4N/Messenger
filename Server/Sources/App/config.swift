import RawDawg
import Vapor
import SystemPackage

func configure(app: Application, db: SharedConnection, videoStoragePath: FilePath, isRelease: Bool) async throws {
    app.http.server.configuration.address = .hostname("0.0.0.0", port: 8080)
    app.middleware = .init()
    app.middleware.use(App.ErrorMiddleware(isRelease: isRelease))
    
    try await db.execute(
        """
        pragma foreign_keys = on;
        pragma journal_mode = wal;
        """)
    try await migrate(db: db, logger: app.logger)

    app.storage[SharedConnection.self] = db
    app.storage[VideoStorageDirectoryKey.self] = videoStoragePath
    
    routes(app)
}

// MARK: Common functionality

extension SharedConnection: StorageKey {
    public typealias Value = SharedConnection
}

struct VideoStorageDirectoryKey: StorageKey {
    public typealias Value = FilePath
}

extension Request {
    var db: SharedConnection {
        self.application.storage[SharedConnection.self]!
    }
    var videoStorageDirectory: FilePath {
        self.application.storage[VideoStorageDirectoryKey.self]!
    }
}

func routes(_ app: Application) {
    app.post("otp", use: requestOTPRoute)
    app.post("login", use: loginRoute)
    app.on(.POST, "registration", body: .collect(maxSize: "10mb"), use: registrationRoute)

    app.get("user", use: findUserRoute)
    app.get("user", ":id", "avatar", use: getUserAvatarRoute)
    
    app.get("private-chats", ":idB", "messages", use: fetchPrivateMessagesRoute)

    app.get("private-chat", use: fetchPrivateChatsRoute)
    app.on(
        .POST, "private-chat", ":otherParticipantID", "send", body: .stream, use: sendMessageRoute)
    
    app.get(
        "private-chat", ":otherParticipantID", "message", ":messageID", "video",
        use: fetchVideoRoute)
}
