import Foundation
import OSLog

struct API {
    static let local = API(base: URL(string: "http://localhost:8080")!)
    static let logger = Logger(subsystem: "com.github.youC4N.videomessenger", category: "Networking")
    
    let endpoint: URL
    
    init(base: URL) {
        self.endpoint = base
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
    case binaryServerError(status: Int)
    case textualServerError(status: Int, response: String)
    case recognizedServerError(status: Int, reason: String)

    var description: String {
        switch self {
        case .nonHTTPResponse(let got):
            "Received a non-HTTP response of type \(got)"
        case .binaryServerError(status: let status):
            "Received a server error with a status: \(status) and binary body. Or is it empty? ¯\\_(ツ)_/¯"
        case .textualServerError(status: let status, response: let response):
            "Received a server error with a status: \(status) and body: \(response)"
        case .recognizedServerError(status: let status, reason: let reason):
            "Received a server error with a status: \(status) and known reason \(reason)"
        }
    }
    
    init(fromResponse res: HTTPURLResponse, data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            self = .binaryServerError(status: res.statusCode)
            return
        }
        struct RecognizedServerError: Decodable {
            var reason: String
        }
        guard let recognized = try? JSONDecoder().decode(RecognizedServerError.self, from: data) else {
            self = .textualServerError(status: res.statusCode, response: text)
            return
        }
        self = .recognizedServerError(status: res.statusCode, reason: recognized.reason)
    }
}
