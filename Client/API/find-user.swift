import Foundation
import MessengerInterface

extension API {
    func findUser(byPhoneNumber number: PhoneNumber, sessionToken: SessionToken) async throws -> FindUserResponse {
        let url = endpoint
            .appending(component: "user")
            .appending(queryItems: [.init(name: "phone", value: number.urlEncoded)])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
        }
        
        switch httpResponse.statusCode {
        case 401: return .unauthorized
        case 404: return .absent
        case 400:
            let errorResponse = try JSONDecoder().decode(CommonErrorResponse.self, from: body)
            return .invalidPhoneNumber(reason: errorResponse.reason)
        case 200:
            let user = try JSONDecoder().decode(User.self, from: body)
            return .found(user)
        default:
            throw ServerRequestError(fromResponse: httpResponse, data: body)
        }
    }
}
