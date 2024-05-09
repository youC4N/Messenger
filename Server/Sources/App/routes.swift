import Vapor
import SQLite

struct MyResponse: Content {
    var code: Int
    var message: String
}

func routes(_ app: Application, db: Connection) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("json") { req async throws in
        MyResponse(code: 69, message: "nice!").status(.imATeapot)
    }
    
    app.get("bazinga") { req async throws in
        try db.prepare("select id, name from bazinga").run().map { row in
            Bazinga(id: row[0] as! Int, name: row[1] as! String)
        }
    }
    
    app.get("bazinga", ":id") { req async throws in
        let id = try req.parameters.require("id", as: Int.self)
        guard let row = try db.prepare("select id, name from bazinga where id = ? limit 1", id)
            .firstRow()
        else {
            return Response(status: .notFound)
        }
        let entity = Bazinga(id: try row.get(at: 0), name: try row.get(at: 1))
        return try await entity.encodeResponse(for: req)
    }
    
    app.post("bazinga") { req async throws in
        let createRequest = try req.content.decode(BazingaCreateRequest.self)
        req.logger.info("Inserting name=\(createRequest.name)")
        guard let res = try db.prepare("insert into bazinga (name) values (?) returning id, name")
            .bind(createRequest.name)
            .firstRow() else { throw MessangerError.serverError }
        return Bazinga(id: try res.get(at: 0), name: try res.get(at: 1))
    }
}

enum MessangerError: Error {
    case serverError
}

struct Bazinga: Content {
    var id: Int
    var name: String
}

struct BazingaCreateRequest: Content {
    var name: String
}
