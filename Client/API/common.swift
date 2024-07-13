import Foundation
import OSLog

struct API {
    static let local = API(base: URL(string: "http://192.168.3.14:8080")!)
    static let logger = Logger(
        subsystem: "com.github.youC4N.videomessenger", category: "Networking")

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
    case unexpectedResponse(message: String)

    var description: String {
        switch self {
        case .nonHTTPResponse(let got):
            "Received a non-HTTP response of type \(got)"
        case .binaryServerError(let status):
            "Received a server error with a status: \(status) and binary body. Or is it empty? ¯\\_(ツ)_/¯"
        case .textualServerError(let status, let response):
            "Received a server error with a status: \(status) and body: \(response)"
        case .recognizedServerError(let status, let reason):
            "Received a server error with a status: \(status) and known reason \(reason)"
        case .unexpectedResponse(let message):
            message
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
        guard let recognized = try? JSONDecoder().decode(RecognizedServerError.self, from: data)
        else {
            self = .textualServerError(status: res.statusCode, response: text)
            return
        }
        self = .recognizedServerError(status: res.statusCode, reason: recognized.reason)
    }
}
