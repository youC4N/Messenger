import RawDawg
import Vapor

struct OTPRequest: Content, Sendable {
    var number: String
}

struct OTPResponse: Content, Sendable {
    var otpToken: String
}

func normalisedPhoneNumber( for number: String) throws -> String {
    let rgReplacingPattern = "[^0-9\\+]"
    let rgPhoneMatchingPattern = "\\+\\d{12,15}"
    var regex = try! NSRegularExpression(pattern: rgReplacingPattern, options: .caseInsensitive)
    let numberRange = NSMakeRange(0, number.count)
    let rawNumber = regex.stringByReplacingMatches(in: number, range: numberRange, withTemplate: "")
    regex = try! NSRegularExpression(pattern: rgPhoneMatchingPattern, options: .caseInsensitive)
    let rawNumberRange = NSMakeRange(0, rawNumber.count)
    let a = regex.firstMatch(in: rawNumber, range: rawNumberRange)
    if a != nil {
        return rawNumber
    } else {
        throw MyError.invalidPhoneNumber
    }
}

private func saveOTP(code: String, token: String, phone: String, in db: Database) async throws {
    try await withContext("Inserting otp password") {
        try await db.prepare(
            """
            insert into one_time_passwords (phone, code, token, expires_at)
            values (\(phone), \(code), \(token), datetime('now', 'utc', 'subsecond', '+5 minutes'));
            """
        ).run()
    }
}

@Sendable
func requestOTPRoute(req: Request) async throws -> OTPResponse {
    let otpReq = try req.content.decode(OTPRequest.self)
    let code = generateOTPCode()
    req.logger.info("Here is your code = \(code)", metadata: ["phoneNumber": "\(otpReq.number)"])
    let token = nanoid()
    let normalisedNumber = try normalisedPhoneNumber(for: otpReq.number)
    try await saveOTP(code: code, token: token, phone: normalisedNumber, in: req.db)
    return OTPResponse(otpToken: token)
}

enum MyError: Error, AbortError {
    case invalidPhoneNumber
    var status: HTTPResponseStatus { .badRequest }
    var reason: String { "Invalid phone number." }
}
