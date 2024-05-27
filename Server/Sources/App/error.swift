import RawDawg
import Vapor

protocol ErrorContext: Error {
    var cause: any Error { get }
    var context: String { get }
    var source: ErrorSource { get }
}

extension ErrorContext {
    func traverseCauseChain() -> (
        rootError: any Error, contextStack: [(context: String, in: ErrorSource)]
    ) {
        var contextStack = [(context: context, in: source)]
        var currentCause = cause
        while let contextful = currentCause as? ErrorContext {
            contextStack.append((context: contextful.context, in: contextful.source))
            currentCause = contextful.cause
        }
        return (currentCause, contextStack)
    }
}

struct WrappedError<Inner: Error>: Error, ErrorContext, CustomStringConvertible {
    let inner: Inner
    let context: String
    let source: ErrorSource

    var cause: any Error { inner }

    var description: String {
        let (rootError, contextStack) = traverseCauseChain()
        var desc = String(describing: rootError)
        for (context, source) in contextStack.reversed() {
            desc +=
                "\n\t- \(context) in \(source.function) (\(source.file):\(source.line):\(source.column))"
        }
        return desc
    }

    func first<T>(ofType type: T.Type) -> T? {
        var currentCause = cause
        while true {
            switch currentCause {
            case let abort as T: return abort
            case let contextful as ErrorContext: currentCause = contextful.cause
            default: return nil
            }
        }
    }
}

// extension WrappedError: AbortError where Inner: AbortError {
//    var reason: String { inner.reason }
//    var status: HTTPResponseStatus { inner.status }
//    var headers: HTTPHeaders { inner.headers }
// }

extension WrappedError: AbortError {
    var reason: String {
        first(ofType: AbortError.self)?.reason ?? HTTPStatus.internalServerError.reasonPhrase
    }

    var status: HTTPStatus {
        first(ofType: AbortError.self)?.status ?? .internalServerError
    }

    var headers: HTTPHeaders {
        first(ofType: AbortError.self)?.headers ?? [:]
    }
}

extension WrappedError: DebuggableError {
    var logLevel: Logger.Level {
        first(ofType: DebuggableError.self)?.logLevel ?? .error
    }
}

@discardableResult
func withContext<T>(
    _ context: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    block: () throws -> T
) throws -> T {
    func wrap<Inner: Error>(_ error: Inner) -> WrappedError<Inner> {
        .init(
            inner: error,
            context: context(),
            source: .init(file: file, function: function, line: line, column: column)
        )
    }

    do {
        return try block()
    } catch let error as Abort {
        throw wrap(error)
    } catch let error as SQLiteError {
        throw wrap(error)
    } catch let error as WrappedError<any Error> {
        throw wrap(error)
    } catch {
        throw wrap(error)
    }
}

@discardableResult
func withContext<T>(
    _ context: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
    column: UInt = #column,
    block: () async throws -> T
) async throws -> T {
    func wrap<Inner: Error>(_ error: Inner) -> WrappedError<Inner> {
        .init(
            inner: error,
            context: context(),
            source: .init(file: file, function: function, line: line, column: column)
        )
    }

    do {
        return try await block()
    } catch let error as Abort {
        throw wrap(error)
    } catch let error as SQLiteError {
        throw wrap(error)
    } catch let error as WrappedError<any Error> {
        throw wrap(error)
    } catch {
        throw wrap(error)
    }
}

extension SQLiteError: AbortError {
    public var status: NIOHTTP1.HTTPResponseStatus {
        .internalServerError
    }
}

/// This is almost the same as the Vapor's built-in `ErrorMiddleware`, except it doesn't do `log.report(error:)`, which relies on `AbortError.reason`.
/// The logging message and the client-facing reason shouldn't be one and the same!
/// Let's use the same mechanism swift uses for error reporting, aka. `CustomStringConvertible`
public struct ErrorMiddleware: AsyncMiddleware {
    var env: Environment

    /// Structure of `ErrorMiddleware` default response.
    struct ErrorResponse: Codable {
        /// Always `true` to indicate this is a non-typical JSON response.
        var error: Bool

        /// The reason for the error.
        var reason: String
    }

    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws
        -> Response
    {
        do {
            return try await next.respond(to: request)
        } catch {
            let status: HTTPResponseStatus
            let reason: String
            let source: ErrorSource
            let level: Logger.Level
            var headers: HTTPHeaders

            // Inspect the error type and extract what data we can.
            switch error {
            case let debugAbort as (DebuggableError & AbortError):
                reason = debugAbort.reason
                status = debugAbort.status
                headers = debugAbort.headers
                source = debugAbort.source ?? .capture()
                level = debugAbort.logLevel

            case let abort as AbortError:
                reason = abort.reason
                status = abort.status
                headers = abort.headers
                source = .capture()
                level = .warning

            case let debugErr as DebuggableError:
                reason = debugErr.reason
                status = .internalServerError
                headers = [:]
                source = debugErr.source ?? .capture()
                level = debugErr.logLevel

            default:
                // In debug mode, provide the error description; otherwise hide it to avoid sensitive data disclosure.
                reason = env.isRelease ? "Something went wrong." : String(describing: error)
                status = .internalServerError
                headers = [:]
                source = .capture()
                level = .warning
            }

            // Report the error
            request.logger.log(
                level: level,
                .init(stringLiteral: String(describing: error)),
                file: source.file,
                function: source.function,
                line: numericCast(source.line)
            )

            // attempt to serialize the error to json
            let body: Response.Body
            do {
                body = try .init(
                    buffer: JSONEncoder().encodeAsByteBuffer(
                        ErrorResponse(error: true, reason: reason),
                        allocator: request.byteBufferAllocator),
                    byteBufferAllocator: request.byteBufferAllocator
                )
                headers.contentType = .json
            } catch {
                body = .init(
                    string: "Oops: \(String(describing: error))\nWhile encoding error: \(reason)",
                    byteBufferAllocator: request.byteBufferAllocator)
                headers.contentType = .plainText
            }

            // create a Response with appropriate status
            return Response(status: status, headers: headers, body: body)
        }
    }
}
