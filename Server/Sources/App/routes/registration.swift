import Vapor
import RawDawg

struct RegistrationRequest: Content, Sendable {
    var registrationToken: String
    var username: String
//    var image: Data?
}

struct RegistrationResponse: Content, Sendable {
    var sessionToken: String
    var userInfo: [String: String]
}



@Sendable
func registrationRoute(req: Request) async throws -> RegistrationResponse {
    let registrationRequest = try req.content.decode(RegistrationRequest.self)
    let userPhoneNumber: String? = try await req.db.prepare(
    """
    select phone from registration_tokens where token = \(registrationRequest.registrationToken);
    """).fetchOptional()
    guard let userPhoneNumber = userPhoneNumber else {
        throw RegistrationErrors.phoneDoesntExistInRegistrationToken
    }
    // TODO: take and save Avatar for every user
    try await req.db.prepare(
    """
    insert into users (first_name, phone_number) values(\(registrationRequest.username), \(userPhoneNumber))
    """).run()
    req.logger.info("new user registrated", metadata: ["name": "\(registrationRequest.username)", "number":"\(userPhoneNumber)"])
    return RegistrationResponse(sessionToken: "rewqr", userInfo: [:])
}


enum RegistrationErrors : Error {
    case phoneDoesntExistInRegistrationToken
}
