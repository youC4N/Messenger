import Foundation

enum FetchAvatarResponse {
    case unauthorized
    case notFound
    case success(Data)
}

extension API {
    func fetchAvatar(ofUser userID: UserID, sessionToken: SessionToken) async throws -> FetchAvatarResponse {
        var request = URLRequest(url: endpoint.appending(components: "user", userID.description, "avatar"))
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                return .unauthorized
            }
            if httpResponse.statusCode == 404 {
                return .notFound
            }
            if httpResponse.statusCode != 200 {
                throw ServerRequestError(fromResponse: httpResponse, data: data)
            }
        }
        
        return .success(data)
    }
}
