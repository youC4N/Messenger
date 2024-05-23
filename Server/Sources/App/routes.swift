import RawDawg
import Vapor

struct MyResponse: Codable, Content {
    var id: Int
    var username: String
    var number: String
}


enum MessangerError: Error {
    case serverError
}

extension Database: StorageKey {
    public typealias Value = Database
}

extension Request {
    var db: Database {
        self.application.storage[Database.self]!
    }
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

func generateOTPCode() -> String {
    let result = Int.random(in: 0..<100000)
    return String(result)
}

func routes(_ app: Application, db: Database) throws {
    app.get("json") { req async throws in
        let users: [MyResponse] = try await db.prepare("select * from users").fetchAll()
        return users
    }
    app.post("otp", use: requestOTPRoute)
    
    app.post("login", use: loginRoute)
    app.post("registration", use: registrationRoute)
    
}





