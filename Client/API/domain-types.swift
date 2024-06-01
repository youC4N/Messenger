import Foundation

struct UserID: RawRepresentable, Codable, CustomStringConvertible, Equatable, Hashable, Comparable, Sendable {
    var rawValue: Int
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    var description: String {
        self.rawValue.description
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SessionToken: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable, CustomStringConvertible {
    var rawValue: String
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    var description: String {
        self.rawValue.description
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct OTPToken: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable, CustomStringConvertible {
    var rawValue: String
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    var description: String {
        self.rawValue.description
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct RegistrationToken: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable, CustomStringConvertible {
    var rawValue: String
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    var description: String {
        self.rawValue.description
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct PhoneNumber: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable, CustomStringConvertible {
    var rawValue: String
    
    init?(rawValue: RawValue) {
        let rgReplacingPattern = "[^0-9\\+]"
        let rgPhoneMatchingPattern = "\\+\\d{12,15}"
        var regex = try! NSRegularExpression(pattern: rgReplacingPattern, options: .caseInsensitive)
        let numberRange = NSMakeRange(0, rawValue.count)
        let rawNumber = regex.stringByReplacingMatches(in: rawValue, range: numberRange, withTemplate: "")
        regex = try! NSRegularExpression(pattern: rgPhoneMatchingPattern, options: .caseInsensitive)
        let rawNumberRange = NSMakeRange(0, rawNumber.count)
        let a = regex.firstMatch(in: rawNumber, range: rawNumberRange)
        if a != nil {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let phone = PhoneNumber(rawValue: try container.decode(RawValue.self)) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid phone number")
        }
        self = phone
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    var description: String {
        self.rawValue.description
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
