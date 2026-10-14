import Foundation

struct MinipError: Error, Codable, LocalizedError {
    enum Code: String, Codable {
        case invalidArgument = "INVALID_ARGUMENT"
        case apiNotFound = "API_NOT_FOUND"
        case notSupported = "NOT_SUPPORTED"
        case notFound = "NOT_FOUND"
        case alreadyExists = "ALREADY_EXISTS"
        case permissionDenied = "PERMISSION_DENIED"
        case invalidState = "INVALID_STATE"
        case ioError = "IO_ERROR"
        case databaseError = "DATABASE_ERROR"
        case internalError = "INTERNAL_ERROR"
    }

    let code: Code
    let message: String
    let details: [String: BridgeValue]?

    init(_ code: Code, _ message: String, details: [String: BridgeValue]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    var errorDescription: String? { message }

    static func invalidArgument(_ name: String) -> MinipError {
        MinipError(.invalidArgument, "Invalid or missing parameter: \(name)", details: ["parameter": .string(name)])
    }

    static func wrapping(_ error: Error) -> MinipError {
        if let error = error as? MinipError { return error }
        let native = error as NSError
        let details: [String: BridgeValue] = [
            "nativeDomain": .string(native.domain),
            "nativeCode": .signed(Int64(native.code)),
        ]
        if let underlying = native.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSPOSIXErrorDomain {
            return wrapping(underlying)
        }
        let code: Code
        if native.domain == NSPOSIXErrorDomain || native.domain == "FileSystemManager" {
            switch Int32(native.code) {
            case ENOENT: code = .notFound
            case EEXIST: code = .alreadyExists
            case EACCES, EPERM: code = .permissionDenied
            case EINVAL, ENOTDIR, EISDIR: code = .invalidArgument
            case EBADF: code = .invalidState
            default: code = .ioError
            }
        } else if native.domain == NSCocoaErrorDomain {
            switch native.code {
            case NSFileNoSuchFileError, NSFileReadNoSuchFileError: code = .notFound
            case NSFileWriteFileExistsError: code = .alreadyExists
            case NSFileReadNoPermissionError, NSFileWriteNoPermissionError: code = .permissionDenied
            default: code = .ioError
            }
        } else if native.domain == NSURLErrorDomain {
            code = .ioError
        } else {
            code = .internalError
        }
        return MinipError(code, native.localizedDescription, details: details)
    }
}
