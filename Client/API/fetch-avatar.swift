import Foundation
import MessengerInterface

extension API {
    func fetchAvatar(ofUser userID: UserID, sessionToken: SessionToken) async throws -> FetchAvatarResponse {
        var request = URLRequest(url: endpoint.appending(components: "user", userID.description, "avatar"))
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }
        
        if httpResponse.statusCode == 401 {
            return .unauthorized
        }
        if httpResponse.statusCode == 404 {
            return .notFound
        }
        if httpResponse.statusCode != 200 {
            throw ServerRequestError(fromResponse: httpResponse, data: data)
        }
        
        guard let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") else {
            throw ServerRequestError.unexpectedResponse(message: "Expected content-type header to be set on an avatar response")
        }
        return .success(data, contentType: MIMEType(rawValue: contentType))
    }
}
