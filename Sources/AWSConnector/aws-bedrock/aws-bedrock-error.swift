import Foundation

public enum BedrockRuntimeError: Error, Sendable, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case http(status: Int, body: String)
    case eventstream(String)
    case service(type: String, message: String?)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid Bedrock Runtime URL: \(value)."

        case .invalidResponse:
            return "Invalid Bedrock Runtime HTTP response."

        case .http(let status, let body):
            return "Bedrock Runtime HTTP error \(status): \(body)"

        case .eventstream(let message):
            return "Bedrock Runtime event stream error: \(message)"

        case .service(let type, let message):
            if let message {
                return "Bedrock Runtime service error \(type): \(message)"
            }

            return "Bedrock Runtime service error \(type)."
        }
    }
}
