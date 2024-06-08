import Foundation

public struct UserID: IntegralNewtype {
    public typealias IntegerLiteralType = Int
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct MessageID: IntegralNewtype {
    public typealias IntegerLiteralType = Int
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct SessionToken: StringNewtype {
    public typealias StringLiteralType = String
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct OTPToken: StringNewtype {
    public typealias StringLiteralType = String
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct RegistrationToken: StringNewtype {
    public typealias StringLiteralType = String
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct PhoneNumber: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable,
    CustomStringConvertible
{
    public var rawValue: String

    public var urlEncoded: String {
        self.rawValue.replacingOccurrences(of: "+", with: "%2B")
    }

    public init?(percentEncoded: String) {
        guard let decoded = percentEncoded.removingPercentEncoding else {
            return nil
        }
        self.init(rawValue: decoded)
    }

    public init?(rawValue: RawValue) {
        let rgReplacingPattern = "[^0-9\\+]"
        let rgPhoneMatchingPattern = "\\+\\d{12,15}"
        var regex = try! NSRegularExpression(pattern: rgReplacingPattern, options: .caseInsensitive)
        let numberRange = NSMakeRange(0, rawValue.count)
        let rawNumber = regex.stringByReplacingMatches(
            in: rawValue, range: numberRange, withTemplate: "")
        regex = try! NSRegularExpression(pattern: rgPhoneMatchingPattern, options: .caseInsensitive)
        let rawNumberRange = NSMakeRange(0, rawNumber.count)
        let a = regex.firstMatch(in: rawNumber, range: rawNumberRange)
        if a != nil {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let phone = PhoneNumber(rawValue: try container.decode(RawValue.self)) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid phone number")
        }
        self = phone
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public var description: String {
        self.rawValue.description
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
