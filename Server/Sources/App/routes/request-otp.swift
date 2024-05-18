import RawDawg
import Vapor

struct OTPRequest: Content, Sendable {
    var number: String
}

struct OTPResponse: Content, Sendable {
    var otpToken: String
}

@Sendable
func requestOTPRoute(req: Request) async throws -> OTPResponse {
    let otpReq = try req.content.decode(OTPRequest.self)
    let code = generateOTPCode()
    req.logger.info("Here is your code = \(code)", metadata: ["phoneNumber": "\(otpReq.number)"])
    let token = nanoid()
    try await req.db.prepare(
        """
        insert into one_time_passwords (phone, code, token, expires_at)
        values (\(otpReq.number), \(code), \(token), datetime('now', 'utc', 'subsecond', '+5 minutes'));
        """
    ).run()
    return OTPResponse(otpToken: token)
}

