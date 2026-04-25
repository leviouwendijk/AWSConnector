import Foundation
import Primitives

public extension Bedrock {
    enum Converse {}
}

public extension Bedrock.Converse {
    enum Role: String, Sendable, Codable, Hashable {
        case user
        case assistant
    }

    struct Request: Sendable, Codable, Hashable {
        public var messages: [Message]
        public var system: [SystemBlock]?
        public var inferenceConfig: Inference?
        public var toolConfig: ToolConfig?

        public init(
            messages: [Message],
            system: [SystemBlock]? = nil,
            inferenceConfig: Inference? = nil,
            toolConfig: ToolConfig? = nil
        ) {
            self.messages = messages
            self.system = system
            self.inferenceConfig = inferenceConfig
            self.toolConfig = toolConfig
        }
    }

    struct Message: Sendable, Codable, Hashable {
        public var role: Role
        public var content: [ContentBlock]

        public init(
            role: Role,
            content: [ContentBlock]
        ) {
            self.role = role
            self.content = content
        }
    }

    struct SystemBlock: Sendable, Codable, Hashable {
        public var text: String

        public init(
            text: String
        ) {
            self.text = text
        }
    }

    struct Inference: Sendable, Codable, Hashable {
        public var maxTokens: Int?
        public var temperature: Double?
        public var topP: Double?
        public var stopSequences: [String]?

        public init(
            maxTokens: Int? = nil,
            temperature: Double? = nil,
            topP: Double? = nil,
            stopSequences: [String]? = nil
        ) {
            self.maxTokens = maxTokens
            self.temperature = temperature
            self.topP = topP
            self.stopSequences = stopSequences
        }
    }

    enum ContentBlock: Sendable, Codable, Hashable {
        case text(String)
        case toolUse(ToolUse)
        case toolResult(ToolResult)

        private enum CodingKeys: String, CodingKey {
            case text
            case toolUse
            case toolResult
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            if let value = try container.decodeIfPresent(
                String.self,
                forKey: .text
            ) {
                self = .text(value)
                return
            }

            if let value = try container.decodeIfPresent(
                ToolUse.self,
                forKey: .toolUse
            ) {
                self = .toolUse(value)
                return
            }

            if let value = try container.decodeIfPresent(
                ToolResult.self,
                forKey: .toolResult
            ) {
                self = .toolResult(value)
                return
            }

            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported Bedrock Converse content block."
                )
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            switch self {
            case .text(let value):
                try container.encode(
                    value,
                    forKey: .text
                )

            case .toolUse(let value):
                try container.encode(
                    value,
                    forKey: .toolUse
                )

            case .toolResult(let value):
                try container.encode(
                    value,
                    forKey: .toolResult
                )
            }
        }
    }
}

public extension Bedrock.Converse {
    struct ToolConfig: Sendable, Codable, Hashable {
        public var tools: [Tool]
        public var toolChoice: ToolChoice?

        public init(
            tools: [Tool],
            toolChoice: ToolChoice? = nil
        ) {
            self.tools = tools
            self.toolChoice = toolChoice
        }
    }

    enum Tool: Sendable, Codable, Hashable {
        case toolSpec(ToolSpec)

        private enum CodingKeys: String, CodingKey {
            case toolSpec
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            self = .toolSpec(
                try container.decode(
                    ToolSpec.self,
                    forKey: .toolSpec
                )
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            switch self {
            case .toolSpec(let value):
                try container.encode(
                    value,
                    forKey: .toolSpec
                )
            }
        }
    }

    struct ToolSpec: Sendable, Codable, Hashable {
        public var name: String
        public var description: String?
        public var inputSchema: ToolInputSchema

        public init(
            name: String,
            description: String? = nil,
            inputSchema: ToolInputSchema
        ) {
            self.name = name
            self.description = description
            self.inputSchema = inputSchema
        }
    }

    struct ToolInputSchema: Sendable, Codable, Hashable {
        public var json: JSONValue

        public init(
            json: JSONValue
        ) {
            self.json = json
        }
    }

    enum ToolChoice: Sendable, Codable, Hashable {
        case auto
        case any
        case tool(name: String)

        private enum CodingKeys: String, CodingKey {
            case auto
            case any
            case tool
        }

        private enum ToolCodingKeys: String, CodingKey {
            case name
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            if container.contains(.auto) {
                self = .auto
                return
            }

            if container.contains(.any) {
                self = .any
                return
            }

            let tool = try container.nestedContainer(
                keyedBy: ToolCodingKeys.self,
                forKey: .tool
            )

            self = .tool(
                name: try tool.decode(
                    String.self,
                    forKey: .name
                )
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            switch self {
            case .auto:
                try container.encode(
                    JSONValue.object([:]),
                    forKey: .auto
                )

            case .any:
                try container.encode(
                    JSONValue.object([:]),
                    forKey: .any
                )

            case .tool(let name):
                var tool = container.nestedContainer(
                    keyedBy: ToolCodingKeys.self,
                    forKey: .tool
                )

                try tool.encode(
                    name,
                    forKey: .name
                )
            }
        }
    }

    struct ToolUse: Sendable, Codable, Hashable {
        public var toolUseId: String
        public var name: String
        public var input: JSONValue

        public init(
            toolUseId: String,
            name: String,
            input: JSONValue
        ) {
            self.toolUseId = toolUseId
            self.name = name
            self.input = input
        }
    }

    struct ToolResult: Sendable, Codable, Hashable {
        public var toolUseId: String
        public var content: [ToolResultContent]
        public var status: ToolResultStatus?

        public init(
            toolUseId: String,
            content: [ToolResultContent],
            status: ToolResultStatus? = nil
        ) {
            self.toolUseId = toolUseId
            self.content = content
            self.status = status
        }
    }

    enum ToolResultStatus: String, Sendable, Codable, Hashable {
        case success
        case error
    }

    enum ToolResultContent: Sendable, Codable, Hashable {
        case json(JSONValue)
        case text(String)

        private enum CodingKeys: String, CodingKey {
            case json
            case text
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            if let value = try container.decodeIfPresent(
                JSONValue.self,
                forKey: .json
            ) {
                self = .json(value)
                return
            }

            if let value = try container.decodeIfPresent(
                String.self,
                forKey: .text
            ) {
                self = .text(value)
                return
            }

            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported Bedrock tool result content block."
                )
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            switch self {
            case .json(let value):
                try container.encode(
                    value,
                    forKey: .json
                )

            case .text(let value):
                try container.encode(
                    value,
                    forKey: .text
                )
            }
        }
    }
}
