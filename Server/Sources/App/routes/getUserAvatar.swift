import RawDawg
import Vapor
// user/:id/avatar

@Sendable
func getUserAvatarRoute(req: Request) async throws -> Response {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else { throw getUserAvatarError.cantParseSessionToken }
    guard let dbSessionToken: String = try await req.db.prepare(
        """
        select session_token from sessions where session_token = \(sessionToken);
        """).fetchOptional() else { throw sessionValidationError.tokenIsNil }
    guard let userID = req.parameters.get("id") else { throw getUserAvatarError.cantParseUserID }
    let avatarBlob: SQLiteBlob? = try await req.db.prepare("select avatar from users where id = \(userID)").fetchOptional()
    guard case .some(.loaded(let bytes)) = avatarBlob else { throw getUserAvatarError.noAvatar }
    var response = Response(status: .ok, body: Response.Body(data: bytes))
    guard let imageType: String = try await req.db.prepare("select avatar_type from users where user_id = \(userID)").fetchOptional()
    else { throw getUserAvatarError.noContentType }
    req.headers.add(name: .contentType, value: imageType)
    req.logger.info("added header to response", metadata: ["headers:": "\(response.headers)"])
    return response
}

enum getUserAvatarError: Error {
    case cantParseSessionToken
    case cantParseUserID
    case cantParseAvatar
    case noAvatar
    case noContentType
}
