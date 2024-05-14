import XCTVapor

@testable import App

final class AppTests: XCTestCase {
    var app: Application!
    var db: Connection!

    override func setUp() async throws {
        self.db = try Connection(":memory:")
        self.app = Application(.testing)
        try await routes(app, db: self.db)
    }
    override func tearDown() async throws {
        self.app.shutdown()
        self.app = nil
    }

    func testHelloWorld() async throws {
        try await self.app.test(
            .GET, "hello",
            afterResponse: { res async in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.body.string, "Hello, world!")
            })
    }
}
