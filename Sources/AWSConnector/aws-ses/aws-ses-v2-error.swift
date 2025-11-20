import Foundation

public enum SESV2Error: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(status: Int, body: String)
    case decodeError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let s):
            return "Invalid SES URL: \(s)"
        case .invalidResponse:
            return "Invalid SES HTTP response."
        case .httpError(let status, let body):
            return "SES HTTP error: \(status) – \(body)"
        case .decodeError(let msg):
            return "Failed to decode SES response: \(msg)"
        }
    }
}
