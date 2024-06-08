import Foundation
import MessengerInterface

extension API {
    func requestOTP(forPhoneNumber phone: PhoneNumber) async throws -> OTPResponse {
        var request = URLRequest(url: endpoint.appending(component: "otp"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OTPRequest(phone: phone))
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }

        API.logger.info("POST /otp response: \(httpResponse.statusCode, privacy: .public)")
        guard httpResponse.statusCode != 400 else {
            let errorResponse = try JSONDecoder().decode(
                ErrorResponse<OTPResponse.ErrorKind>.self, from: body)
            return .invalidPhoneNumber(reason: errorResponse.reason)
        }
        guard httpResponse.statusCode == 200 else {
            let error = ServerRequestError(fromResponse: httpResponse, data: body)

            API.logger.error("Server error occurred for POST /login \(error, privacy: .public)")
            throw error
        }

        let decoded = try JSONDecoder().decode(OTPResponse.Success.self, from: body)
        return .success(decoded)
    }
}
