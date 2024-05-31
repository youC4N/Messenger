import Logging
import RawDawg

private let migrations = [
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
    """,
    """
        alter table users add column avatar blob null;
    """
    ,
    """
        alter table users add column avatar_type text null;
    """
]

func migrate(db: Database, logger: Logger) async throws {
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
        logger.info("Applied migration #\(idx + 1): \(migration)")
    }
}
