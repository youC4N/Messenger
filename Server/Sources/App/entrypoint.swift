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
        let db = try SharedConnection(filename: dbpath)
        try await configure(app: app, db: db, videoStoragePath: videoStoragePath, isRelease: env.isRelease)
        defer { app.shutdown() }
        try await app.execute()
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

