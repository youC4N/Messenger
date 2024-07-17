import Logging
import RawDawg
import SystemPackage
import Vapor

#if canImport(LoggingOSLog)
    import LoggingOSLog
#endif

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()

        #if canImport(LoggingOSLog)
        LoggingSystem.bootstrap {
            LoggingOSLog(label: $0)
        }
        #else
            try LoggingSystem.bootstrap(from: &env)
        #endif

        let dbpath = ProcessInfo.processInfo.environment["DB_PATH"] ?? "./db.sqlite"
        guard let videoStoragePathStr = ProcessInfo.processInfo.environment["VIDEO_STORAGE"] else {
            fatalError(
                "Application can't start with VIDEO_STORAGE environment varible set to the path where the video assets are to be stored"
            )
        }
        let videoStoragePath = FilePath(videoStoragePathStr)
        try FileManager.default.createDirectory(
            at: URL(filePath: videoStoragePath, directoryHint: .isDirectory)!,
            withIntermediateDirectories: true)

        let app = try await Application.make(env)
        app.http.server.configuration.address = .hostname("0.0.0.0", port: 8080)
        app.middleware = .init()
        app.middleware.use(App.ErrorMiddleware(env: env))
        let db = try SharedConnection(filename: dbpath)
        try await db.execute(
            """
            pragma foreign_keys = on;
            pragma journal_mode = wal;
            """)
        try await migrate(db: db, logger: app.logger)

        app.storage[SharedConnection.self] = db
        app.storage[VideoStorageDirectoryKey.self] = videoStoragePath
        defer { app.shutdown() }
        routes(app)
        try await app.execute()
    }
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

extension URL {
    init?(filePath: SystemPackage.FilePath, directoryHint: URL.DirectoryHint = .inferFromPath) {
        guard let string = String(validating: filePath) else {
            return nil
        }
        self.init(filePath: string, directoryHint: directoryHint)
    }
}

func nanoid(
    alphabet: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz-",
    size: Int = 21
) -> String {
    assert(!alphabet.isEmpty)
    assert(size >= 0)
    return String(alphabet.randomSample(count: size))
}

// MARK: Route definitions

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
