import RawDawg
import XCTVapor
import SystemPackage
import MessengerInterface

@testable import App

final class AppTests: XCTestCase {
    var app: Application!
    var tmpdirURL: URL!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        let db = try SharedConnection(filename: ":memory:")
        
        self.tmpdirURL = FileManager.default.temporaryDirectory.appending(components: "com.github.youC4N.videmessenger.testing", UUID().uuidString)
        try FileManager.default.createDirectory(at: self.tmpdirURL, withIntermediateDirectories: true)
        let tmpdirFilePath = tmpdirURL.withUnsafeFileSystemRepresentation { FilePath(platformString: $0!) }
        
        try await configure(app: app, db: db, videoStoragePath: tmpdirFilePath, isRelease: false)
    }
    
    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
        try FileManager.default.removeItem(at: self.tmpdirURL)
        self.tmpdirURL = nil
    }

    func testSendsOTPTokenToTheValidPhoneNumber() async throws {
        let validPhone = PhoneNumber(rawValue: "+380999999999")!
        
        try await self.app.test(
            .POST, "otp",
            beforeRequest: { req in
                try req.content.encode(OTPRequest(phone: validPhone), using: JSONEncoder())
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(OTPResponse.Success.self)
                XCTAssert(!body.otpToken.rawValue.isEmpty)
            }
        )
    }
    
    func testRejectsOTPTokenToInvalidPhoneNumber() async throws {
        
    }
}
