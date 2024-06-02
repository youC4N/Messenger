import Foundation

/// Structure of `ErrorMiddleware` default response.
// struct CommonErrorResponse: Codable {
// }

public struct ErrorResponse<Code>: Codable where Code: RawRepresentable, Code.RawValue == String, Code: Codable {
    /// Always `true` to indicate this is a non-typical JSON response.
    public let error: Bool = true

    /// Human readable, and end-user presentable description of the error
    public var reason: String

    /// Developer-facing, machine identifiable identifier that specifies concrete kind of error
    public var code: Code
    
    public init(_ code: Code, reason: String) {
        self.code = code
        self.reason = reason
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<ErrorResponse<Code>.CodingKeys> = try decoder.container(keyedBy: ErrorResponse<Code>.CodingKeys.self)
        self.reason = try container.decode(String.self, forKey: ErrorResponse<Code>.CodingKeys.reason)
        self.code = try container.decode(Code.self, forKey: ErrorResponse<Code>.CodingKeys.code)
    }
}
