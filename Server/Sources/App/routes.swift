import RawDawg
import Vapor

struct MyResponse: Codable, Content {
    var id: Int
    var username: String
    var number: String
}

struct OTPRequest: Codable, Content {
    var id: Int
    var number: String
}

struct OTPResponse: Content {
    var otpToken: String
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
    app.post("otp") { req async throws in
        let otpReq = try req.content.decode(OTPRequest.self)
        let code = generateOTPCode()
        req.logger.info("Here is your code = \(code)", metadata: ["phoneNumber": otpReq.number])
        let token = nanoid()
        try await db.prepare(
            """
            insert into users (number, code, token, expires_at)
            values (\(otpReq.number), \(code), \(token), datetime('now', 'utc', 'subsecond', '+5 minutes')
            """
        ).run()
        return OTPResponse(otpToken: token)
    }

}

enum MessangerError: Error {
    case serverError
}

struct Bazinga: Content {
    var id: Int
    var name: String
}
