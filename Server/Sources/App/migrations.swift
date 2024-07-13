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
    """,
    """
    alter table users add column avatar_type text null;
    """,
    """
    alter table private_chats
        drop column message_count;
    alter table private_chats
        add column last_message_id integer null references private_messages(id);

    create index private_chats_last_message_id on private_chats(last_message_id);
    """,
    """
    create table video_uploads (
        id integer primary key autoincrement,
        file_path text not null,
        created_at text not null default (datetime('now', 'subsec'))
    );
    alter table private_messages
        drop column video_blob;
    alter table private_messages
        add column upload_id not null references video_uploads(id);
    alter table private_messages
        add column author_id not null references users(id);
    create unique index private_messages_upload_id on private_messages(upload_id);
    create unique index private_messages_order_in_chat on private_messages(chat_id, message_order);
    -- Don't really think we need this one. Although, who knows
    -- create index private_messages_author_id on private_messages(author_id);
    """,
    """
    alter table video_uploads
        add column file_size integer null;
    """,
]

func migrate(db: SharedConnection, logger: Logger) async throws {
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
        logger.info("Applied migration #\(maxIdx + idx + 1): \(migration)")
    }
}
