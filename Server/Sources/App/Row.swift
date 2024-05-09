import SQLite

enum BindingError: Error {
    case datatypeAndSQLTypeIsNotTheSame
}

struct Row {
    var bindings: [(any Binding)?]
    func get<T: Value>(_ as: T.Type, idx: Int) throws -> T.ValueType {
        let raw = bindings[idx]
        guard let value = raw as? T.Datatype else {
            throw BindingError.datatypeAndSQLTypeIsNotTheSame
        }
        return try T.fromDatatypeValue(value)
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

