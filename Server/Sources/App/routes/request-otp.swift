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
    //req.logger.info("number and rawNumber", metadata: ["number": "\(number)", "rawNumber": "\(rawNumber)"])
    regex = try! NSRegularExpression(pattern: rgPhoneMatchingPattern, options: .caseInsensitive)
    let rawNumberRange = NSMakeRange(0, rawNumber.count)
    let a = regex.firstMatch(in: rawNumber, range: rawNumberRange)
    //req.logger.info("regex firstMatch", metadata: ["a":"\(String(describing: a))"])
    if a != nil {
        return rawNumber
    } else {
        throw MyError.smthWithNumber
    }
    //return ""

}

@Sendable
func requestOTPRoute(req: Request) async throws -> OTPResponse {
    
//    let a = try normalisedPhoneNumber(req: req, for: "+38()(*(0506371561")
//    let b = try normalisedPhoneNumber(req: req, for: "+(380)50-637-15-61")
//    let c = try normalisedPhoneNumber(req: req, for: "+ 3 8 0 5 0 6 3 7 1 5 6 1 adf")
//    let d = try normalisedPhoneNumber(req: req, for: "+380506371561")
    //req.logger.info("test normilized string ", metadata: ["+38()(*(0506371561": "\(a)", "+(380)50-637-15-61": "\(b)", "+ 3 8 0 5 0 6 3 7 1 5 6 1 adf":"\(c)", "+380506371561":"\(d)"])
    let otpReq = try req.content.decode(OTPRequest.self)
    let code = generateOTPCode()
    req.logger.info("Here is your code = \(code)", metadata: ["phoneNumber": "\(otpReq.number)"])
    let token = nanoid()
    let normalisedNumber = try normalisedPhoneNumber(for: otpReq.number)
    try await req.db.prepare(
        """
        insert into one_time_passwords (phone, code, token, expires_at)
        values (\(normalisedNumber), \(code), \(token), datetime('now', 'utc', 'subsecond', '+5 minutes'));
        """
    ).run()
    return OTPResponse(otpToken: token)
}

enum MyError: Error {
    case smthWithNumber
}
