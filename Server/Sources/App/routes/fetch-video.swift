import Foundation
import MessengerInterface
import NIOFileSystem
import SystemPackage
import Vapor

private struct QueryParams: Decodable {
    var sessionToken: SessionToken
}

@Sendable
func fetchVideoRoute(req: Request) async throws -> Response {
    let query = try req.query.decode(QueryParams.self)
    guard var userAID = try await sessionUser(from: query.sessionToken, in: req.db) else {
        throw Abort(.unauthorized, reason: "Unauthorized.")
    }
    guard var userBID: UserID = req.parameters.get("otherParticipantID") else {
        throw Abort(.badRequest, reason: "otherParticipantID path parameter is not supplied.")
    }
    guard let messageID: MessageID = req.parameters.get("messageID") else {
        throw Abort(.badRequest, reason: "messageID path parameter is not supplied.")
    }
    guard userAID != userBID else {
        throw Abort(.badRequest, reason: "Chats with oneself are prohibited.")
    }
    if userAID > userBID {
        swap(&userAID, &userBID)
    }

    let upload: (FilePath, Int64?)? = try await req.db.prepare(
        """
        select video_uploads.file_path, video_uploads.file_size
        from private_chats
        join private_messages
          on private_chats.id = private_messages.chat_id
        join video_uploads
          on video_uploads.id = private_messages.upload_id
        where participant_a_id = \(userAID)
          and participant_b_id = \(userBID)
          and private_messages.id = \(messageID)
        """
    ).fetchOptional()

    guard let (path, fileSize) = upload else {
        throw Abort(.notFound, reason: "No such message.")
    }

    let range = fileRange(httpRange: req.headers.range, fileSize: fileSize)
    if case .outOfBounds(let requested, let expected) = range {
        req.logger.trace(
            "Requested a video fragment range that is out of bounds",
            metadata: [
                "requested": "\(requested.serialize())",
                "expected": "\(expected.lowerBound)-\(expected.upperBound)",
            ])
        throw Abort(
            .rangeNotSatisfiable,
            reason:
                "Requested a video fragment range that is out of bounds. "
                + "Requested: \(requested.serialize()). "
                + "Expected: \(expected.lowerBound)-\(expected.upperBound)")
    }
    if case .fallback(let reason, let requested) = range {
        req.logger.warning(
            "Requested an unsupported range: \(reason). Falling back to full content",
            metadata: ["requested": "\(requested.serialize())"])
    }

    let contentLength =
        switch range {
        case .range(let range, fileSize: _):
            range.count
        case .full, .fallback(reason: _, requested: _), .outOfBounds(requested: _, expected: _):
            Int(fileSize ?? -1)
        }

    let status: HTTPResponseStatus =
        switch range {
        case .full, .fallback(reason: _, requested: _):
            .ok
        case .range:
            .partialContent
        case .outOfBounds(requested: _, expected: _):
            .rangeNotSatisfiable
        }

    var headers: HTTPHeaders = [
        "Content-Type": "video/quicktime",
        "Accept-Ranges": "bytes",
    ]

    switch range {
    case .range(let range, let fileSize):
        headers.add(
            name: "Content-Range",
            value: "bytes \(range.lowerBound)-\(range.upperBound)/\(fileSize)")
    case .full, .fallback(reason: _, requested: _):
        break
    case .outOfBounds(requested: _, expected: _):
        fatalError(
            "Unreachable. This case should've been matched and dealt with before."
        )
    }

    let body = Response.Body(
        managedAsyncStream: { writer in
            let bytesWritten = try await streamFile(at: path, within: range, into: writer)

            if contentLength != -1, bytesWritten != contentLength {
                req.logger.warning(
                    "The expected body size, and actual one differs",
                    metadata: ["expected": "\(contentLength)", "actual": "\(bytesWritten)"])
            }
            req.logger.info(
                "Sent video stream of \(bytesWritten) bytes",
                metadata: ["messageID": "\(messageID)"])
        }, count: contentLength)

    return Response(status: status, headers: headers, body: body)
}

enum RequestedRange {
    case full
    case fallback(reason: String, requested: HTTPHeaders.Range)
    case range(ClosedRange<Int64>, fileSize: Int64)
    case outOfBounds(requested: HTTPHeaders.Range.Value, expected: ClosedRange<Int64>)
}

func fileRange(httpRange range: HTTPHeaders.Range?, fileSize: Int64?) -> RequestedRange {
    guard let range else { return .full }
    guard let fileSize else {
        return .fallback(reason: "We haven't somehow persisted file length", requested: range)
    }
    assert(fileSize > 0)
    guard range.unit == .bytes else {
        return .fallback(reason: "Non byte ranges are not supported", requested: range)
    }
    guard let span = range.ranges.first else {
        return .fallback(reason: "Multipart ranges are not supported", requested: range)
    }

    let lastByteIdx = fileSize - 1
    let fileRange = 0...lastByteIdx
    let requestedRange =
        switch span {
        case .start(value: let start):
            Int64(start)...fileSize
        case .tail(value: let tail):
            0...Int64(tail)
        case .within(let start, let end):
            Int64(start)...Int64(end)
        }

    assert(requestedRange.lowerBound >= 0)
    assert(requestedRange.upperBound >= 0)

    return if fileRange.contains(requestedRange) {
        .range(requestedRange, fileSize: fileSize)
    } else {
        .outOfBounds(requested: span, expected: fileRange)
    }
}

extension ClosedRange where Bound: Comparable {
    /// Whether the current range completely encompases the other one.
    /// - Returns:
    /// `true`, if the other range is a subset of this one
    func contains(_ other: Self) -> Bool {
        self.lowerBound <= other.lowerBound && self.upperBound >= other.upperBound
    }
}

/// - Returns
/// Amount of bytes written to the stream
func streamFile(
    at path: FilePath, within range: RequestedRange, into writer: any AsyncBodyStreamWriter
) async throws -> Int {
    var bytes = 0
    try await FileSystem.shared.withFileHandle(forReadingAt: path) { file in
        let chunks =
            switch range {
            case .full, .fallback(reason: _, requested: _):
                file.readChunks()
            case .range(let range, fileSize: _):
                file.readChunks(in: range)
            case .outOfBounds(requested: _, expected: _):
                fatalError(
                    "This case should've been matched and dealt with before entering file streaming block."
                )
            }

        for try await chunk in chunks {
            try await writer.write(.buffer(chunk))
            bytes += chunk.readableBytesView.count
        }
    }
    return bytes
}
