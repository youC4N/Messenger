import Foundation
import Vapor
import RawDawg

enum findUserResponse: Content{
    case invalidSessionToken
    case userDoesntExist
    case userFound(username: String, id: Int)
}


// TODO: fix nahui niche ne rabotaet
@Sendable
func findUserRoute(req: Request) async throws -> findUserResponse {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else{ throw sessionValidationError.tokenIsNil}
    guard let dbSessionToken: String = try await req.db.prepare(
        """
        select session_token from sessions where session_token = \(sessionToken);
        """).fetchOptional() else {throw sessionValidationError.tokenIsNil}
    guard let number = req.parameters.get("phone") else {throw findUserError.phoneIsNil}
    let normNumber = try normalisedPhoneNumber(for: number)
    //req.logger.info("request headers: ", metadata: ["headers":"\(req.headers)"])
    
    
    req.logger.info("Successfully parsed", metadata: ["number":"\(number)", "sessionToken":"\(sessionToken)"])
    let userInfo: (Int, String)? = try await req.db.prepare(
        "select id, first_name from users where phone_number = \(normNumber);")
        .fetchOptional()
    
    guard let (userID, username) = userInfo else{
        req.logger.info("There is no such number in db", metadata: ["number" : "\(normNumber)"])
        return .userDoesntExist
    }
    req.logger.info("User info:", metadata: ["username":"\(username)", "userID":"\(userID)"])
    
    return .userFound(username: username, id: userID)
    
    
    
    
}

enum findUserError: Error {
    case phoneIsNil
    case userIDIsnotInUsers
}

enum sessionValidationError: Error {
    case tokenIsNil
}
