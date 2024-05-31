import Logging
import RawDawg
import Vapor

var env = try Environment.detect()

#if canImport(LoggingOSLog)
    import LoggingOSLog
    LoggingSystem.bootstrap(LoggingOSLog.init)
#else
    try LoggingSystem.bootstrap(from: &env)
#endif

let dbpath = ProcessInfo.processInfo.environment["DB_PATH"] ?? "./db.sqlite"

let app = try await Application.make(env)
app.middleware = .init()
app.middleware.use(App.ErrorMiddleware(env: env))
let db = try Database(filename: dbpath)
try await migrate(db: db, logger: app.logger)

app.storage[Database.self] = db
defer { app.shutdown() }
routes(app)
try await app.execute()

// MARK: Common functionality

extension Database: StorageKey {
    public typealias Value = Database
}

extension Request {
    var db: Database {
        self.application.storage[Database.self]!
    }
}

enum MessangerError: Error {
    case serverError
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
    app.get("getUser", ":phone", use: findUserRoute)
    app.on(.POST, "registration", body: .collect(maxSize: "10mb"), use: registrationRoute)
    app.get("user", ":id", "avatar", use: getUserAvatarRoute)
}
