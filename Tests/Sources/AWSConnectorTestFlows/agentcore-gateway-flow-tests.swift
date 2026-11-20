import AWSConnector
import Foundation
import TestFlows

enum AgentCoreGatewayFlowTests {
    static func webSearchToolCall() -> TestFlow {
        TestFlow(
            "agentcore-web-search-tool-call",
            tags: [
                "aws",
                "agentcore",
                "gateway",
                "web-search",
                "mcp",
            ]
        ) {
            let response = """
            {
              "jsonrpc": "2.0",
              "id": "test-tool-call",
              "result": {
                "isError": false,
                "content": [
                  {
                    "type": "text",
                    "text": "{\"id\":\"search-1\",\"results\":[{\"text\":\"Swift 6.2 release notes\",\"publishedDate\":\"2026-08-01\",\"url\":\"https://swift.org/blog/swift-6.2-released/\",\"title\":\"Swift 6.2 Released\"}]}"
                  }
                ]
              }
            }
            """

            let client = AgentCoreGatewayClient(
                gatewayIdentifier: "gateway-test",
                region: "us-east-1",
                credentials: BedrockFlowSession.credentials(),
                session: BedrockFlowSession.session(
                    response: .init(
                        headers: [
                            "Content-Type": "application/json",
                        ],
                        body: Data(
                            response.utf8
                        )
                    )
                )
            )

            let result = try await client
                .webSearch()
                .search(
                    .init(
                        query: "Swift 6.2",
                        maxResults: 3,
                        filters: .init(
                            domainFilter: .init(
                                include: [
                                    "swift.org",
                                ]
                            ),
                            publishedDateFilter: .init(
                                from: "2026-08-01T00:00:00Z"
                            )
                        )
                    )
                )

            try Expect.equal(
                result.id,
                "search-1",
                "search id"
            )
            try Expect.equal(
                result.results.count,
                1,
                "search result count"
            )

            let first = try Expect.notNil(
                result.results.first,
                "first result"
            )

            try Expect.equal(
                first.text,
                "Swift 6.2 release notes",
                "search result text"
            )

            let recorded = try Expect.notNil(
                BedrockFlowURLProtocol.recorded().first,
                "recorded gateway request"
            )

            let url = try Expect.notNil(
                recorded.request.url,
                "gateway URL"
            )

            try Expect.equal(
                recorded.request.httpMethod,
                "POST",
                "gateway method"
            )
            try Expect.equal(
                url.host,
                "gateway-test.gateway.bedrock-agentcore.us-east-1.amazonaws.com",
                "gateway host"
            )
            try Expect.equal(
                url.path,
                "/mcp",
                "gateway MCP path"
            )
            try Expect.equal(
                recorded.request.value(
                    forHTTPHeaderField: "MCP-Protocol-Version"
                ),
                "2026-07-28",
                "MCP protocol version"
            )
            try Expect.equal(
                recorded.request.value(
                    forHTTPHeaderField: "Mcp-Method"
                ),
                "tools/call",
                "MCP method"
            )
            try Expect.equal(
                recorded.request.value(
                    forHTTPHeaderField: "Mcp-Name"
                ),
                "web-search-tool___WebSearch",
                "MCP tool name"
            )

            let authorization = try Expect.notNil(
                recorded.request.value(
                    forHTTPHeaderField: "Authorization"
                ),
                "authorization"
            )

            try Expect.true(
                authorization.contains(
                    "/us-east-1/bedrock-agentcore/aws4_request"
                ),
                "AgentCore Gateway request uses bedrock-agentcore SigV4 service"
            )

            let body = String(
                decoding: recorded.body,
                as: UTF8.self
            )

            try Expect.true(
                body.contains(
                    "\"method\":\"tools/call\""
                ),
                "MCP request body carries tools/call"
            )
            try Expect.true(
                body.contains(
                    "\"name\":\"web-search-tool___WebSearch\""
                ),
                "MCP request body carries WebSearch tool name"
            )
            try Expect.true(
                body.contains(
                    "\"query\":\"Swift 6.2\""
                ),
                "WebSearch request carries query"
            )
            try Expect.true(
                body.contains(
                    "swift.org"
                ),
                "WebSearch request carries domain filter"
            )

            return [
                .field(
                    "host",
                    url.host ?? "<nil>"
                ),
                .field(
                    "tool",
                    "web-search-tool___WebSearch"
                ),
                .field(
                    "search-id",
                    result.id
                ),
                .value(
                    "results",
                    result.results.count
                ),
            ]
        }
    }
}
