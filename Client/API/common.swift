import Foundation
import OSLog

struct API {
    static let local = API(baseURL: "http://localhost:8080")
    static let logger = Logger(subsystem: "com.github.youC4N.videomessenger", category: "Networking")
    
    let endpoint: URL
    
    init(baseURL: StaticString) {
        self.endpoint = URL(string: baseURL.description)!
    }
}

extension Result where Failure == any Error {
    init(catching block: () async throws -> Success) async {
        do {
            self = .success(try await block())
        } catch {
            self = .failure(error)
        }
    }
}

struct CommonErrorResponse: Codable {
    var reason: String
}

enum ServerRequestError: Error, CustomStringConvertible {
    case nonHTTPResponse(got: Any.Type)
    case serverError(status: Int, message: String?)

    var description: String {
        switch self {
        case .nonHTTPResponse(let got):
            return "Received a non-HTTP response of type \(got)"
        case .serverError(let status, let message):
            return "Received a server error with a status: \(status) and body \(message ?? "<binary>")"
        }
    }
}
