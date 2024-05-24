import Vapor
import RawDawg


// TODO: expiration check
struct RegistrationRequest: Content, Sendable {
    var registrationToken: String
    var username: String
//    var image: Data?
}

struct RegistrationResponse: Content, Sendable {
    var sessionToken: String
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
    
    let userID: Int = try await req.db.prepare("select id from users where phone_number = \(userPhoneNumber)").fetchOptional()!
    let sessionToken = try await createSession(for: userID, in: req)
    req.logger.info("Registration session created", metadata: ["userID": "\(userID)", "sessionToken": "\(sessionToken)"])
    return RegistrationResponse(sessionToken: sessionToken)
}


enum RegistrationErrors : Error {
    case phoneDoesntExistInRegistrationToken
}
