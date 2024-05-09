import Vapor
import Logging
import SQLite

let migrations = [
    """
    create table bazinga (
        id integer primary key autoincrement,
        name text not null
    );
    """,
]

func migrate(db: Connection) throws {
    try db.prepare("""
        create table if not exists migrations (
            idx integer not null,
            applied_at text not null
        )
        """).run()
    
    let maxIdx = Int(try db.scalar("select max(idx) from migrations") as? Int64 ?? 0)
    
    for (idx, migration) in migrations[maxIdx...].enumerated() {
        try db.execute("""
            begin;
            \(migration)
            insert into migrations (idx, applied_at) values (\(idx + maxIdx + 1), datetime());
            commit;
            """)
    }
}

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let dbpath = ProcessInfo.processInfo.environment["DB_PATH"] ?? "./db.sqlite"

        let db = try Connection(dbpath)
        try migrate(db: db)

        let app = Application(env)
        defer { app.shutdown() }
        
        if app.logger.logLevel == .trace {
            db.trace { app.logger.trace("\($0)") }
        }

        do {
            try routes(app, db: db)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.execute()
    }
}
