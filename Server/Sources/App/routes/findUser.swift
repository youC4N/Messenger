import Foundation
import Vapor
import RawDawg

enum findUserResponse: Content{
    case foo
   case invalidSessionToken
    case userFound(username: String, id: String)
}


// TODO: fix nahui niche ne rabotaet
//@Sendable
//func findUser(req: Request) async throws -> findUserResponse {
//    guard let number = req.parameters.get("phone") else {throw findUserError.phoneIsNil}
//    let normNumber = try normalisedPhoneNumber(for: number)
//    return findUserResponse.foo
//    guard let sessionToken: String = req.headers.bearerAuthorization?.token else{ findUserError.sessionTokeIsNil}
//    let userInfo: String? = try await req.db.prepare(
//        """
//        select id, username from users where number = \(normNumber)
//        """).fetchOptional()
//    guard let userID: String = userInfo?.first else{
//        throw findUserError.userIDIsnotInUsers
//    }
//    guard let dbSessionToken:String = try await req.db.prepare(
//        """
//        select session_token from sessions where user_id = \(userID)
//        """).fetchOptional() else {
//        return findUserResponse.invalidSessionToken
//        
//    }
//    guard sessionToken == dbSessionToken else {
//        return findUserResponse.invalidSessionToken
//    }
//    
//    return .userFound(username: <#T##String#>, id: <#T##String#>)
//    
//    
//    
//    
//}

enum findUserError: Error {
    case phoneIsNil
    case sessionTokeIsNil
    case userIDIsnotInUsers
}
