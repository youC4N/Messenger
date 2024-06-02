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

public extension Newtype {
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

public extension InfalibleNewtype {
    init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
}

public protocol IntegralNewtype: InfalibleNewtype, ExpressibleByIntegerLiteral
where RawValue: ExpressibleByIntegerLiteral, RawValue.IntegerLiteralType == Self.IntegerLiteralType
{
}

public extension IntegralNewtype {
    init(integerLiteral value: Self.IntegerLiteralType) {
        let a = RawValue(integerLiteral: value)
        self.init(rawValue: a)
    }
}

public protocol StringNewtype: InfalibleNewtype, ExpressibleByStringLiteral
where RawValue: ExpressibleByStringLiteral, RawValue.StringLiteralType == Self.StringLiteralType
{
}

public extension StringNewtype {
    init(stringLiteral value: Self.StringLiteralType) {
        let a = RawValue(stringLiteral: value)
        self.init(rawValue: a)
    }
}
