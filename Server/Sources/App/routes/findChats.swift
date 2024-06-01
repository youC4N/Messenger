import RawDawg
import Vapor

struct UsersInfo: Content {
    var user: [String: Int]
}

@Sendable func findChatsRoute(req: Request) async throws -> UsersInfo {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Invalid session token.")
    }

    guard let initialID: Int = req.parameters.get("id") else {
        throw Abort(.internalServerError, reason: "Missing phone path parameter.")
    }
    let a = [1, 2]
    let b = [3]
    var userIDs: [Int] = []
    var userNames: [String] = []
    var arr: [(Int, Int)] = try await req.db.prepare(
        """
        select participant_a_id, participant_b_id from private_chats where participant_a_id = \(initialID) or participant_b_id = \(initialID);

        """
    ).fetchAll()
    // how to decode fcking fetchall
    for element in arr {
        if element.0 != initialID {
            userIDs.append(element.0)
            guard
                let str: String = try await req.db.prepare(
                    """
                    select first_name from users where id = \(element.0);
                    """
                ).fetchOptional()
            else {
                throw Abort(
                    .internalServerError, reason: "first_name for id - \(element.0) is absent")
            }
            userNames.append(str)
        } else {
            userIDs.append(element.1)
            let foo = element.1
            guard
                let str: String = try await req.db.prepare(
                    """
                    select first_name from users where id = \(element.1);
                    """
                ).fetchOptional()
            else {
                throw Abort(
                    .internalServerError, reason: "first_name for id - \(element.1) is absent")
            }
            userNames.append(str)
        }
    }


    req.logger.info("test logger at the end == ", metadata: ["chatIDS:": "\(userIDs)", "usernames":"\(userNames)"])


    return UsersInfo(user: Dictionary(uniqueKeysWithValues: zip(userNames, userIDs)))
}
