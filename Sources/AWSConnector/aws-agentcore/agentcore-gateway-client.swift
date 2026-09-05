import Foundation

public struct AgentCoreGatewayClient:
    Sendable
{
    public static let protocolVersion = "2026-07-28"

    public let gatewayIdentifier: String
    public let region: String
    public let credentials: AWSCredentials
    public let host: String
    public let session: URLSession

    public init(
        gatewayIdentifier: String,
        region: String,
        credentials: AWSCredentials,
        host: String? = nil,
        session: URLSession = .shared
    ) {
        self.gatewayIdentifier = gatewayIdentifier
        self.region = region
        self.credentials = credentials
        self.host = host
            ?? "\(gatewayIdentifier).gateway.bedrock-agentcore.\(region).amazonaws.com"
        self.session = session
    }

    public static func resolve(
        gatewayIdentifier: String,
        region: String
    ) throws -> Self {
        .init(
            gatewayIdentifier: gatewayIdentifier,
            region: region,
            credentials: try AWSCredentials.resolve()
        )
    }

    public func callTool<Arguments>(
        _ name: String,
        arguments: Arguments,
        requestID: String = UUID().uuidString
    ) async throws -> AgentCoreGatewayToolResult
    where Arguments: Encodable & Sendable
    {
        let body: Data

        do {
            body = try JSONEncoder().encode(
                AgentCoreGatewayToolCallRequest(
                    id: requestID,
                    name: name,
                    arguments: arguments
                )
            )
        } catch {
            throw AgentCoreGatewayError.encode(
                error.localizedDescription
            )
        }

        let urlString = "https://\(host)/mcp"

        guard let url = URL(
            string: urlString
        ) else {
            throw AgentCoreGatewayError.invalidURL(
                urlString
            )
        }

        var request = URLRequest(
            url: url
        )
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(
            "application/json, text/event-stream",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            host,
            forHTTPHeaderField: "Host"
        )
        request.setValue(
            Self.protocolVersion,
            forHTTPHeaderField: "MCP-Protocol-Version"
        )
        request.setValue(
            "tools/call",
            forHTTPHeaderField: "Mcp-Method"
        )
        request.setValue(
            name,
            forHTTPHeaderField: "Mcp-Name"
        )

        let signer = AWSSigV4Signer(
            credentials: credentials,
            region: region,
            service: "bedrock-agentcore"
        )

        try signer.sign(
            request: &request,
            body: body
        )

        let (data, response) = try await session.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse else {
            throw AgentCoreGatewayError.invalidResponse
        }

        guard (200..<300).contains(
            http.statusCode
        ) else {
            throw AgentCoreGatewayError.http(
                status: http.statusCode,
                body: String(
                    decoding: data,
                    as: UTF8.self
                )
            )
        }

        let envelope: AgentCoreGatewayRPCResponse

        do {
            envelope = try JSONDecoder().decode(
                AgentCoreGatewayRPCResponse.self,
                from: data
            )
        } catch {
            throw AgentCoreGatewayError.decode(
                error.localizedDescription
            )
        }

        if let error = envelope.error {
            throw AgentCoreGatewayError.rpc(
                code: error.code,
                message: error.message
            )
        }

        guard let result = envelope.result else {
            throw AgentCoreGatewayError.missingResult
        }

        if result.isError {
            let message = result.content
                .compactMap(\.text)
                .joined(
                    separator: "\n"
                )

            throw AgentCoreGatewayError.tool(
                message.isEmpty
                    ? "Unknown tool error."
                    : message
            )
        }

        return result
    }
}

public struct AgentCoreGatewayToolResult:
    Sendable,
    Decodable
{
    public let isError: Bool
    public let content: [AgentCoreGatewayToolContent]

    private enum CodingKeys:
        String,
        CodingKey
    {
        case isError
        case content
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.isError = try container.decodeIfPresent(
            Bool.self,
            forKey: .isError
        ) ?? false

        self.content = try container.decodeIfPresent(
            [AgentCoreGatewayToolContent].self,
            forKey: .content
        ) ?? []
    }
}

public struct AgentCoreGatewayToolContent:
    Sendable,
    Decodable
{
    public let type: String
    public let text: String?
}

private struct AgentCoreGatewayRPCResponse:
    Decodable
{
    let result: AgentCoreGatewayToolResult?
    let error: AgentCoreGatewayRPCError?
}

private struct AgentCoreGatewayRPCError:
    Decodable
{
    let code: Int
    let message: String
}

private struct AgentCoreGatewayToolCallRequest<Arguments>:
    Encodable
where Arguments: Encodable
{
    let jsonrpc = "2.0"
    let id: String
    let method = "tools/call"
    let params: Parameters

    init(
        id: String,
        name: String,
        arguments: Arguments
    ) {
        self.id = id
        self.params = .init(
            name: name,
            arguments: arguments
        )
    }

    struct Parameters:
        Encodable
    {
        let name: String
        let arguments: Arguments
        let meta = Metadata()

        private enum CodingKeys:
            String,
            CodingKey
        {
            case name
            case arguments
            case meta = "_meta"
        }
    }
}

private struct AgentCoreGatewayMetadata:
    Encodable
{
    let protocolVersion = AgentCoreGatewayClient.protocolVersion
    let clientInfo = AgentCoreGatewayClientInfo()
    let clientCapabilities: [String: String] = [:]

    private enum CodingKeys:
        String,
        CodingKey
    {
        case protocolVersion = "io.modelcontextprotocol/protocolVersion"
        case clientInfo = "io.modelcontextprotocol/clientInfo"
        case clientCapabilities = "io.modelcontextprotocol/clientCapabilities"
    }
}

private struct AgentCoreGatewayClientInfo:
    Encodable
{
    let name = "awsconnector"
    let version = "1.0.0"
}

private extension AgentCoreGatewayToolCallRequest.Parameters {
    typealias Metadata = AgentCoreGatewayMetadata
}
