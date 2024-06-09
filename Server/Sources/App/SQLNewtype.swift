import MessengerInterface
import RawDawg

protocol SQLNewtype: RawRepresentable, SQLPrimitiveDecodable, SQLPrimitiveEncodable {}

extension SQLNewtype {
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

extension UserID: SQLNewtype {}
extension SessionToken: SQLNewtype {}
extension OTPToken: SQLNewtype {}
extension RegistrationToken: SQLNewtype {}
extension PhoneNumber: SQLNewtype {}
extension MIMEType: SQLNewtype {}
extension MessageID: SQLNewtype {}
