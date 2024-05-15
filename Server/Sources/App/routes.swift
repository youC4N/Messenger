import RawDawg
import Vapor

struct MyResponse: Codable, Content {
    var usernames: String
}

func routes(_ app: Application, db: Database) throws {
    app.get("json") { req async throws in
        let a: [MyResponse] = try await db.prepare("select first_name as usernames from users").fetchAll()
        return a
    }
}

enum MessangerError: Error {
    case serverError
}

struct Bazinga: Content {
    var id: Int
    var name: String
}

struct BazingaCreateRequest: Content {
    var name: String
}
