import Foundation

public enum AgentCore {}

public extension AgentCore {
    enum WebSearch {}
}

public extension AgentCore.WebSearch {
    struct Request:
        Sendable,
        Encodable,
        Hashable
    {
        public let query: String
        public let maxResults: Int?
        public let filters: Filters?

        public init(
            query: String,
            maxResults: Int? = nil,
            filters: Filters? = nil
        ) {
            self.query = query
            self.maxResults = maxResults
            self.filters = filters
        }
    }

    struct Filters:
        Sendable,
        Encodable,
        Hashable
    {
        public let domainFilter: DomainFilter?
        public let publishedDateFilter: PublishedDateFilter?

        public init(
            domainFilter: DomainFilter? = nil,
            publishedDateFilter: PublishedDateFilter? = nil
        ) {
            self.domainFilter = domainFilter
            self.publishedDateFilter = publishedDateFilter
        }
    }

    struct DomainFilter:
        Sendable,
        Encodable,
        Hashable
    {
        public let include: [String]?
        public let exclude: [String]?

        public init(
            include: [String]? = nil,
            exclude: [String]? = nil
        ) {
            self.include = include
            self.exclude = exclude
        }
    }

    struct PublishedDateFilter:
        Sendable,
        Encodable,
        Hashable
    {
        public let from: String?
        public let to: String?

        public init(
            from: String? = nil,
            to: String? = nil
        ) {
            self.from = from
            self.to = to
        }
    }

    struct Response:
        Sendable,
        Decodable,
        Hashable
    {
        public let id: String
        public let results: [Result]
    }

    struct Result:
        Sendable,
        Decodable,
        Hashable
    {
        public let text: String
        public let publishedDate: String?
        public let url: String?
        public let title: String?
    }
}

public struct AgentCoreWebSearchClient:
    Sendable
{
    public let gateway: AgentCoreGatewayClient
    public let toolName: String

    public init(
        gateway: AgentCoreGatewayClient,
        targetName: String = "web-search-tool"
    ) {
        self.gateway = gateway
        self.toolName = "\(targetName)___WebSearch"
    }

    public init(
        gateway: AgentCoreGatewayClient,
        toolName: String
    ) {
        self.gateway = gateway
        self.toolName = toolName
    }

    public func search(
        _ request: AgentCore.WebSearch.Request
    ) async throws -> AgentCore.WebSearch.Response {
        let result = try await gateway.callTool(
            toolName,
            arguments: request
        )

        for content in result.content {
            guard content.type == "text",
                  let text = content.text,
                  let data = text.data(
                    using: .utf8
                  ),
                  let response = try? JSONDecoder().decode(
                    AgentCore.WebSearch.Response.self,
                    from: data
                  )
            else {
                continue
            }

            return response
        }

        throw AgentCoreGatewayError.missingWebSearchPayload
    }
}

public extension AgentCoreGatewayClient {
    func webSearch(
        targetName: String = "web-search-tool"
    ) -> AgentCoreWebSearchClient {
        .init(
            gateway: self,
            targetName: targetName
        )
    }
}
