import XCTVapor
import RawDawg

@testable import App

final class AppTests: XCTestCase {
    var app: Application!
    var db: Database!

    override func setUp() async throws {
        self.db = try Database(filename: ":memory:")
        self.app = Application(.testing)
        try routes(app, db: self.db)
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
