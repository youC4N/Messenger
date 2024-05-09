import Vapor

struct WithStatus<T: AsyncResponseEncodable & Encodable> {
    var status: HTTPStatus
    var inner: T
}

extension WithStatus: Encodable {
    func encode(to encoder: any Encoder) throws {
        try self.inner.encode(to: encoder)
    }
}

extension WithStatus: AsyncResponseEncodable {
    func encodeResponse(for request: Vapor.Request) async throws -> Vapor.Response {
        return try await self.inner.encodeResponse(status: self.status, for: request)
    }
}

struct WithHeaders<T: AsyncResponseEncodable & Encodable> {
    var headers: HTTPHeaders
    var inner: T
}

extension WithHeaders: Encodable {
    func encode(to encoder: any Encoder) throws {
        try self.inner.encode(to: encoder)
    }
}

extension WithHeaders: AsyncResponseEncodable {
    func encodeResponse(for request: Vapor.Request) async throws -> Vapor.Response {
        let response = try await self.inner.encodeResponse(for: request)
        for (name, value) in self.headers {
            response.headers.replaceOrAdd(name: name, value: value)
        }
        return response
    }
}

extension Content {
    func status(_ status: HTTPStatus) -> WithStatus<Self> {
        WithStatus(status: status, inner: self)
    }
    
    func headers(_ headers: HTTPHeaders) -> WithHeaders<Self> {
        WithHeaders(headers: headers, inner: self)
    }
}

