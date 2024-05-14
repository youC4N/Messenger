import Logging
import RawDawg
import Vapor

let migrations = [
    """
    create table bazinga (
        id integer primary key autoincrement,
        name text not null
    );
    create table users(first_name text);
    """
]

func migrate(db: Database) async throws {
    try await db.prepare(
        """
        create table if not exists migrations (
            idx integer not null,
            applied_at text not null
        )
        """
    ).run()

    let maxIdx: Int = try await db.prepare("select max(idx) from migrations").fetchOne()

    for (idx, migration) in migrations[maxIdx...].enumerated() {
        try await db.execute(
            """
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
        let input = [
            "Aaran", "Aaren", "Aarez", "Aarman", "Aaron", "Aaron-James", "Aarron", "Aaryan",
            "Aaryn", "Aayan", "Aazaan", "Abaan", "Abbas", "Abdallah", "Abdalroof", "Abdihakim",
            "Abdirahman", "Abdisalam", "Abdul", "Abdul-Aziz", "Abdulbasir", "Abdulkadir",
            "Abdulkarem", "Abdulkhader", "Abdullah", "Abdul-Majeed", "Abdulmalik", "Abdul-Rehman",
            "Abdur", "Abdurraheem", "Abdur-Rahman", "Abdur-Rehmaan", "Abel", "Abhinav",
            "Abhisumant", "Abid", "Abir", "Abraham", "Abu", "Abubakar", "Ace", "Adain", "Adam",
            "Adam-James", "Addison", "Addisson", "Adegbola", "Adegbolahan", "Aden", "Adenn", "Adie",
            "Adil", "Aditya", "Adnan", "foo",
        ]
        let dbpath = ProcessInfo.processInfo.environment["DB_PATH"] ?? "./db.sqlite"

        let db = try Database(filename: dbpath)
        for name in input {
            try await db.prepare("insert into users(first_name) values(\(name)").run()
        }
        try await migrate(db: db)

        let app = Application(env)
        defer { app.shutdown() }

        do {
            try routes(app, db: db)
        } catch {
            app.logger.report(error: error)
            throw error
        }
        try await app.execute()
    }
}
