import SQLite

enum BindingError: Error, CustomStringConvertible {
    case datatypeAndSQLTypeIsNotTheSame(expected: Any.Type, got: Any.Type?, idx: Int)
    
    var description: String {
        return switch self {
        case .datatypeAndSQLTypeIsNotTheSame(expected: let expected, got: nil, idx: let idx):
            "Cannot retrieve desired type \(expected) from Row at index \(idx). Got NULL from sqlite"
        case .datatypeAndSQLTypeIsNotTheSame(expected: let expected, got: let got?, idx: let idx):
            "Cannot retrieve desired type \(expected) from Row at index \(idx). Got \(got) from sqlite instead"
        }
    }
}

struct Row {
    var bindings: [(any Binding)?]
    func get<T: Value>(at idx: Int, as: T.Type) throws -> T.ValueType {
        let raw = bindings[idx]
        guard let value = raw as? T.Datatype else {
            let expected = T.Datatype.self
            let got = raw.map { Mirror(reflecting: $0).subjectType }
            throw BindingError.datatypeAndSQLTypeIsNotTheSame(expected: expected, got: got, idx: idx)
        }
        return try T.fromDatatypeValue(value)
    }
    
    func get<T: Value>(at idx: Int) throws -> T where T.ValueType == T {
        return try self.get(at: idx, as: T.self)
    }
}

extension Statement {
    func firstRow() throws -> Row? {
        let iter = makeIterator()
        guard let row = try iter.failableNext() else { return nil }
        return Row(bindings: row)
    }
}

// Because the author of the library said so.
// It has a serial queue per thread, as such it should be thread-safe
extension Connection: @unchecked Sendable {}
