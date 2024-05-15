import RawDawg
import Vapor

struct MyResponse: Codable, Content {
    var id: Int
    var username: String
}

func routes(_ app: Application, db: Database) throws {
    app.get("json") { req async throws in
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
