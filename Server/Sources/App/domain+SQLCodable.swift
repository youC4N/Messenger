import MessengerInterface
import RawDawg

protocol NewtypeSQLCodable: RawRepresentable, SQLPrimitiveDecodable, SQLPrimitiveEncodable {}

extension NewtypeSQLCodable {
    public init?(fromSQL primitive: SQLiteValue) where RawValue == Int {
        guard case .integer(let int) = primitive else {
            return nil
        }
        self.init(rawValue: Int(int))
    }
    
    public init?(fromSQL primitive: SQLiteValue) where RawValue == String {
        guard case .text(let string) = primitive else {
            return nil
        }
        self.init(rawValue: string)
    }

    public func encode() -> RawDawg.SQLiteValue where RawValue == Int {
        .integer(Int64(rawValue))
    }
    
    public func encode() -> RawDawg.SQLiteValue where RawValue == String {
        .text(rawValue)
    }
}

extension UserID: NewtypeSQLCodable {}
extension SessionToken: NewtypeSQLCodable {}
extension OTPToken: NewtypeSQLCodable {}
extension RegistrationToken: NewtypeSQLCodable {}
extension PhoneNumber: NewtypeSQLCodable {}
extension MIMEType: NewtypeSQLCodable {}
