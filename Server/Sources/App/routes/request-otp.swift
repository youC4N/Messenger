import MessengerInterface
import RawDawg
import Vapor

extension OTPResponse.Success: Content {}
extension OTPResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .invalidPhoneNumber(let reason):
            try await ErrorResponse(Self.ErrorKind.invalidPhoneNumber, reason: reason)
                .encodeResponse(status: .badRequest, for: request)
        case .success(let success):
            try await success.encodeResponse(for: request)
        }
    }
}

@Sendable
func requestOTPRoute(req: Request) async throws -> OTPResponse {
    let otpReq = try req.content.decode(OTPRequest.self)
    let code = generateOTPCode()
    req.logger.info("Here is your code = \(code)", metadata: ["phoneNumber": "\(otpReq.phone)"])
    let token = OTPToken(rawValue: nanoid())
    guard let normalisedNumber = PhoneNumber(rawValue: otpReq.phone) else {
        return .invalidPhoneNumber()
    }
    try await saveOTP(code: code, token: token, phone: normalisedNumber, in: req.db)
    return .success(.init(otpToken: token))
}

private let otpAlphabet = "0123456789"

private func generateOTPCode(size: Int = 6) -> String {
    String(otpAlphabet.randomSample(count: size))
}

private func saveOTP(code: String, token: OTPToken, phone: PhoneNumber, in db: Database)
    async throws
{
    try await withContext("Inserting otp password") {
        try await db.prepare(
            """
            insert into one_time_passwords (phone, code, token, expires_at)
            values (\(phone), \(code), \(token), datetime('now', 'utc', 'subsecond', '+5 minutes'));
            """
        ).run()
    }
}
