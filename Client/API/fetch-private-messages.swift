import Foundation
import MessengerInterface



extension API {
    func fetchPrivateMessages(byIDB idB: UserID, sessionToken: SessionToken) async throws
        -> FetchPrivateMessagesResponse
    {
        let url =
            endpoint
            .appending(components: "private-chats", "\(idB)", "messages")
            .appending(queryItems: [.init(name: "sessionToken", value: sessionToken.rawValue)])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        


        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: Mirror(reflecting: response).subjectType)
        }

        switch httpResponse.statusCode {
        case 401: return .unauthorized
//        case 404: return .absent
//        case 400:
//            let errorResponse = try JSONDecoder().decode(CommonErrorResponse.self, from: body)
//            return .invalidPhoneNumber(reason: errorResponse.reason)
        case 200:
            let resultArr = try JSONDecoder().decode([MYMessage].self, from: body)
            return .success(resultArr)
        default:
            throw ServerRequestError(fromResponse: httpResponse, data: body)
        }
    }
}
