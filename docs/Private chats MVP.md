#  Private messages MVP design doc

## Data model

```sql
alter table users 
    add column created_at text not null default (datetime('now', 'subsec')),
    add constraint phone_numbers_are_unique unique (phone_number); -- Will also create an index


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

-- CREATE FK INDICES, Egor

create table private_messages (
    id integer primary key autoincrement,
    chat_id integer not null references private_chats(id) on delete cascade,
    video_blob blob not null,
    message_order integer not null,
    created_at text not null default (datetime('now', 'subsec'))
);
```

```ts
type PageInfo = {
    hasPreviousPage: boolean
    hasNextPage: boolean
    startCursor: string
    endCursor: string
}
type Edge<T> = {
    node: T
    cursor: string
}
```

## API endpoints
## GET `/private_chat?before,after,first,last`
**Requires authorization**

Return the paginated list of private, non-empty chats user has engaged with

### Parameters:
- Query `first`: Fetch first N messages, starting from the very beginning, where the N is the `first` parameter
- Query `last`: Fetch last N messages, starting from the very end, where N is the `last` parameter
- Query `after`, `first`: Fetch first `first` messages, after the message with id `after`
- Query `before`, `last`: Fetch last `last` messages, before the message with id `before`

### Response:

#### 200 OK
`application/json`
```ts
{ 
    pageInfo: PageInfo, 
    edges: [Edge<{ 
        id: number,
        otherParticipant: { id: number, phone: string, username: string }
    }>]
}
```
#### 401 No session token / invalid session
`application/json`
```ts
{ error: "Unauthorized" }
````

## POST `/new_private_chat/:phone`
**Requires authorization**

Look up an existing, or create a new chat.

### Parameters:
- Path `phone`: a phone number of the other participant
### Response:
#### 200 OK
`application/json`
```ts
{ chatID: number }
```
#### 404 User with the phone number `phone` doesn't exist in the system
`application/json`
```ts
{ error: "Phone number :phone doesn't exists in the system" }
```
#### 401 No session token / invalid session
`application/json`
```ts
{ error: "Unauthorized" }
```

## POST `/private_chat/:chatID/send`
**Required authorization**

Send a video message to the chat

### Parameters
- Path `chatID`: The id of the chat where to send the new message to
- Body `multipart/form-data`:
  - video `video/mp4; codecs="dvhe"`: The video file itself
### Response:
#### 200 OK
`application/json`
```ts
{ id: number, sentAt: Date }
```
#### 404 No chat for id `chatID` / User is not one of the participants in the chat
`application/json`
```ts
{ error: "Chat with the id :chatID not found" }
```
- 400 `application/json`: `{ error: "Video is too large" }`
#### 401 No session token / invalid session
`application/json`
```ts
{ error: "Unauthorized" }
```

## GET `/private_chat/:chatID/history?before,after,first,last`
**Requries authorization**

Retrieve the paginated list of chat messages in the chat history.

### Parameters
- Path `chatID`: The chat for which the history should be retrieved
- Query `first`: Fetch first N messages, starting from the very beginning, where the N is the `first` parameter
- Query `last`: Fetch last N messages, starting from the very end, where N is the `last` parameter
- Query `after`, `first`: Fetch first `first` messages, after the message with id `after`
- Query `before`, `last`: Fetch last `last` messages, before the message with id `before`

### Response
#### 200 OK
`application/json`
```ts
{ 
    pageInfo: PageInfo, 
    edges: [Edge<{ 
        id: number,
        otherParticipant: { id: number, phone: string, username: string }
    }>]
}
```
#### 404 No chat for id `chatID` / User is not one of the participants in the chat
`application/json`
```ts
{ error: "Chat with the id :chatID not found" }
```
#### 401 No session token / invalid session
`application/json`
```ts
{ error: "Unauthorized" }
```

## GET `/private_chat/:chatID/message/:messageID/video`
**Required authorization**

Fetch the video file for the message `messageID` in chat `chatID`. Also, would be great to support streaming, and http request ranges.

### Parameters
- Path `chatID`
- Path `messageID`

### Response
#### 200 OK
`video/mp4; codecs="dvhe"` 
The video file itself

#### 404 No chat for id `chatID` / User is not one of the participants in the chat
`application/json`
```ts
{ error: "Chat with the id :chatID not found" }
```
#### 404 No message with id `messageID` in chat `chatID`
`application/json`
```ts
{ error: "Message with the id :messageID not found in chat :chatID" }
```
#### 401 No session token / invalid session
`application/json`
```ts
{ error: "Unauthorized" }
```