import Vapor
import NIO
import Foundation
import RawDawg

enum newMessageResponse: Content, Codable {
    case unauthorized
    case success
}

@Sendable
func createNewMessageRoute(for req: Request) async throws -> newMessageResponse {
    guard let sessionToken: String = req.headers.bearerAuthorization?.token else {
        return .unauthorized
    }
    guard try await sessionTokenExists(token: sessionToken, in: req.db) else {
        return .unauthorized
    }
    guard let userBID = req.parameters.get("idB") else {
        req.logger.error("createNewMessageRoute doesn't have :idB path parameter")
        throw Abort(.internalServerError)
    }
    guard let userAID = try await sessionUser(from: sessionToken, in: req.db) else {
        return .unauthorized
    }

    // Decode the incoming video data
    let byteBuffer = try req.content.decode(ByteBuffer.self)
    let data = Data(buffer: byteBuffer)

    // Ensure the "video" directory exists
    let fileManager = FileManager.default
    let videoDirectory = DirectoryConfiguration.detect().workingDirectory + "video"
    if !fileManager.fileExists(atPath: videoDirectory) {
        try fileManager.createDirectory(atPath: videoDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    // Save the video data to a file
    let videoFilename = UUID().uuidString + ".mov"
    let videoPath = videoDirectory + "/" + videoFilename
    let videoURL = URL(fileURLWithPath: videoPath)
    try data.write(to: videoURL)

    req.logger.info("Video saved to \(videoPath)")

    return .success
}
