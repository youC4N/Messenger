import Foundation

public protocol Newtype: RawRepresentable, Codable, CustomStringConvertible, Equatable, Hashable,
    Comparable, Sendable
where
    RawValue: CustomStringConvertible, RawValue: Comparable, RawValue: Equatable, RawValue: Codable,
    RawValue: Hashable
{
}

public protocol InfalibleNewtype: Newtype {
    init(rawValue: RawValue)
}

extension Newtype {
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

extension InfalibleNewtype {
    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
}

public protocol IntegralNewtype: InfalibleNewtype, ExpressibleByIntegerLiteral, LosslessStringConvertible
where RawValue: ExpressibleByIntegerLiteral, RawValue.IntegerLiteralType == Self.IntegerLiteralType, RawValue: LosslessStringConvertible
{
}

extension IntegralNewtype {
    public init(integerLiteral value: Self.IntegerLiteralType) {
        let a = RawValue(integerLiteral: value)
        self.init(rawValue: a)
    }
    
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

public protocol StringNewtype: InfalibleNewtype, ExpressibleByStringLiteral
where RawValue: ExpressibleByStringLiteral, RawValue.StringLiteralType == Self.StringLiteralType, RawValue: LosslessStringConvertible {
}

extension StringNewtype {
    public init(stringLiteral value: Self.StringLiteralType) {
        let a = RawValue(stringLiteral: value)
        self.init(rawValue: a)
    }
    
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
