import Foundation

public enum SigV4Error: Error, LocalizedError {
    case missingURL
    case hmacFailure(String)

    public var errorDescription: String? {
        switch self {
        case .missingURL:
            return "SigV4 signing failed: request URL is missing."
        case .hmacFailure(let msg):
            return "SigV4 signing failed: \(msg)"
        }
    }
}
