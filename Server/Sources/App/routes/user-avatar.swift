import MessengerInterface
import RawDawg
import Vapor

extension FetchAvatarResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        switch self {
        case .unauthorized:
            try await ErrorResponse(Self.ErrorKind.unauthorized, reason: "Unauthorized.")
                .encodeResponse(status: .unauthorized, for: request)
        case .notFound:
            try await ErrorResponse(
                Self.ErrorKind.notFound, reason: "No avatar image for this user id."
            )
            .encodeResponse(status: .notFound, for: request)
        case .success(let bytes, let contentType):
            Response(
                status: .ok,
                headers: ["Content-Type": contentType.description],
                body: .init(data: bytes)
            )
        }
    }
}

@Sendable
func getUserAvatarRoute(req: Request) async throws -> FetchAvatarResponse {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        return .unauthorized
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        return .unauthorized
    }

    guard let userID = req.parameters.get("id") else {
        req.logger.error("getUserAvatarRoute doesn't have :id path parameter")
        throw Abort(.internalServerError)
    }

    let row: (SQLiteBlob, MIMEType)? = try await req.db.prepare(
        "select avatar, avatar_type from users where id = \(userID)"
    )
    .fetchOptional()
    guard let (blob, contentType) = row else {
        return .notFound
    }

    guard case .loaded(let bytes) = blob else {
        req.logger.error("Retrieved avatar blob which isn't .loaded")
        throw Abort(.internalServerError)
    }
    return .success(bytes, contentType: contentType)
}
