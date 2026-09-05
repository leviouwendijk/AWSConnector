import Foundation

public enum AgentCoreGatewayError:
    Error,
    Sendable,
    LocalizedError
{
    case invalidURL(String)
    case invalidResponse
    case http(status: Int, body: String)
    case rpc(code: Int, message: String)
    case missingResult
    case tool(String)
    case missingWebSearchPayload
    case encode(String)
    case decode(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid AgentCore Gateway URL: \(value)."

        case .invalidResponse:
            return "Invalid AgentCore Gateway HTTP response."

        case .http(let status, let body):
            return "AgentCore Gateway HTTP error \(status): \(body)"

        case .rpc(let code, let message):
            return "AgentCore Gateway MCP error \(code): \(message)"

        case .missingResult:
            return "AgentCore Gateway MCP response did not contain a tool result."

        case .tool(let message):
            return "AgentCore Gateway tool call failed: \(message)"

        case .missingWebSearchPayload:
            return "AgentCore Web Search response did not contain a decodable search payload."

        case .encode(let message):
            return "Failed to encode AgentCore Gateway request: \(message)"

        case .decode(let message):
            return "Failed to decode AgentCore Gateway response: \(message)"
        }
    }
}
