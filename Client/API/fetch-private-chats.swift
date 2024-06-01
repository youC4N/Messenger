import Foundation

struct User: Equatable, Identifiable, Decodable {
    var id: Int
    var username: String
}

enum FetchPrivateChatsResponse {
    case unauthorized
    case success([User])
}

extension API {
    func fetchPrivateChats(sessionToken: String) async throws -> FetchPrivateChatsResponse {
        var request = URLRequest(url: endpoint.appending(components: "private-chats"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (body, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = httpResponse as? HTTPURLResponse else {
            throw MYError.unknownURLresponse
        }
        guard httpResponse.statusCode != 401 else {
            return .unauthorized
        }
        guard httpResponse.statusCode == 200 else {
            let error = ServerRequestError(fromResponse: httpResponse, data: body)
            
            API.logger.error("Server error occurred for GET /private-chat \(error, privacy: .public)")
            throw error
        }
        let users = try JSONDecoder().decode([User].self, from: body)
        
        return .success(users)
    }
}
