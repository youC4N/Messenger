import Foundation
import MessengerInterface

extension API {
    func authenticate(forCode code: String, otpToken token: OTPToken) async throws -> LoginResponse {
        API.logger.info("Authenticating with code: \(code, privacy: .private), for token: \(token.description, privacy: .private)")
        
        var request = URLRequest(url: endpoint.appending(component: "login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(code: code, token: token))
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerRequestError.nonHTTPResponse(got: type(of: response))
        }
        
        API.logger.info("POST /login response: \(httpResponse.statusCode, privacy: .public)")
        guard httpResponse.statusCode == 200 else {
            switch try? JSONDecoder().decode(ErrorResponse<LoginResponse.ErrorKind>.self, from: body) {
            case .some(let error) where error.code == .expired:
                return .expired(reason: error.reason)
            case .some(let error) where error.code == .invalid:
                return .invalid(reason: error.reason)
            default:
                let error = ServerRequestError(fromResponse: httpResponse, data: body)
                
                API.logger.error("Server error occurred for POST /login \(error, privacy: .public)")
                throw error
            }
        }
        
        let decoded = try JSONDecoder().decode(LoginResponse.Success.self, from: body)
        return .success(decoded)
    }
}
