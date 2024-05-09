import SQLite

enum BindingError: Error {
    case datatypeAndSQLTypeIsNotTheSame
}

struct Row {
    var bindings: [(any Binding)?]
    func get<T: Value>(at idx: Int, as: T.Type) throws -> T.ValueType {
        let raw = bindings[idx]
        guard let value = raw as? T.Datatype else {
            throw BindingError.datatypeAndSQLTypeIsNotTheSame
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
