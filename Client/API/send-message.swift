import Foundation
import MessengerInterface

extension API {
    func sendMessage(to otherParticipant: UserID, videoFile: URL, sessionToken: SessionToken) async throws -> NewMessageResponse {
        let url = endpoint.appending(components: "private-chat", String(otherParticipant), "send")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("video/mp4; codecs=dhve", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        let (body, response) = try await URLSession.shared.upload(for: request, fromFile: videoFile)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }

        API.logger.info("POST /private-chat/\(otherParticipant, privacy: .private)/send response: \(httpResponse.statusCode, privacy: .public)")
        guard httpResponse.statusCode < 400 || httpResponse.statusCode >= 500 else {
            let errorResponse = try JSONDecoder().decode(
                ErrorResponse<NewMessageResponse.ErrorKind>.self, from: body)
            return switch errorResponse.code {
            case .unauthorized:
                .unauthorized
            case .unsupportedMediaFormat:
                .unsupportedMediaFormat(reason: errorResponse.reason)
            case .invalidRecipient:
                .invalidRecipient(reason: errorResponse.reason)
            }
        }
        guard httpResponse.statusCode == 200 else {
            let error = ServerRequestError(fromResponse: httpResponse, data: body)

            API.logger.error("Server error occurred for POST /login \(error, privacy: .public)")
            throw error
        }

        let decoded = try JSONDecoder().decode(Message.self, from: body)
        return .success(decoded)
    }
}
