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

let db = try Database(filename: dbpath)
try await migrate(db: db, logger: app.logger)

let app = try await Application.make(env)
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
    alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~_",
    size: Int = 21
) -> String {
    assert(!alphabet.isEmpty)
    assert(size >= 0)
    var result = ""
    for _ in 0..<size {
        let ch = alphabet.randomElement()!
        result.append(ch)
    }
    return result
}

// MARK: Route definitions

func routes(_ app: Application) {
    app.post("otp", use: requestOTPRoute)
    app.post("login", use: loginRoute)
    app.post("registration", use: registrationRoute)

}
