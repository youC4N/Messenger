import Foundation
import MessengerInterface

extension API {
    func fetchPrivateChats(sessionToken: SessionToken) async throws -> FetchPrivateChatsResponse {
        var request = URLRequest(url: endpoint.appending(components: "private-chat"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }
        guard httpResponse.statusCode != 401 else {
            return .unauthorized
        }
        guard httpResponse.statusCode == 200 else {
            let error = ServerRequestError(fromResponse: httpResponse, data: body)

            API.logger.error(
                "Server error occurred for GET /private-chat \(error, privacy: .public)")
            throw error
        }
        let users = try JSONDecoder().decode([User].self, from: body)

        return .success(users)
    }
}
