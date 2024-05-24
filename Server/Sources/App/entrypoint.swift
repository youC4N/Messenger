import Logging
import RawDawg
import Vapor
#if canImport(LoggingOSLog)
import LoggingOSLog
#endif

let migrations = [
    """
    create table users(
    id integer primary key autoincrement,
    first_name text not null,
    phone_number text not null,
    created_at text not null default (datetime('now', 'subsec')),
    constraint phone_numbers_are_unique unique (phone_number)
    ); -- Will also create an index
    """,
    """
    create table if not exists one_time_passwords(
        id integer primary key autoincrement,
        phone text not null,
        code text not null,
        token text not null,
        expires_at text not null
    );
    """,
    // yarik forgor 💀
    """
    create table if not exists registration_tokens(
        id integer primary key autoincrement,
        token text not null,
        phone text not null,
        expires_at text not null
    );
    create index registration_tokens_tokens on registration_tokens(token);
    create index one_time_passwords_tokens on one_time_passwords(token);
    create index registration_tokens_expires_at on registration_tokens(expires_at);
    create index one_time_passwords_expires_at on one_time_passwords(expires_at);
    """,
    """
    create table sessions(
    id integer primary key autoincrement,
    session_token text not null,
    user_id integer not null
    );
    """,
    """
    create table private_chats (
        id integer primary key autoincrement,
        participant_a_id integer not null references users(id) on delete cascade,
        participant_b_id integer not null references users(id) on delete cascade,
        message_count integer not null default 0,
        created_at text not null default (datetime('now', 'subsec')),
        
        constraint participant_a_id_is_less_than_b_id check (participant_a_id < participant_b_id),
        -- This also automagically creates an index we'll use for the lookups
        constraint private_chats_are_unique unique (participant_a_id, participant_b_id)
    );
    """,
    """
    create table private_messages (
        id integer primary key autoincrement,
        chat_id integer not null references private_chats(id) on delete cascade,
        video_blob blob not null,
        message_order integer not null,
        created_at text not null default (datetime('now', 'subsec'))
    );
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

    let maxIdx: Int = try await db.prepare("select max(idx) from migrations").fetchOne() ?? 0

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
        #if canImport(LoggingOSLog)
        LoggingSystem.bootstrap(LoggingOSLog.init)
        #else
        try LoggingSystem.bootstrap(from: &env)
        #endif
        
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
        try await migrate(db: db)
        
        let app = try await Application.make(env)
        app.storage[Database.self] = db
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
