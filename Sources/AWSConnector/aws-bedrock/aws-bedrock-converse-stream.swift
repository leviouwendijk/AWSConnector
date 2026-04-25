import Foundation
import Primitives

public extension Bedrock.Converse {
    enum StreamEvent: Sendable, Hashable {
        case messageStart(MessageStart)
        case blockStart(BlockStart)
        case blockDelta(BlockDelta)
        case blockStop(BlockStop)
        case messageStop(MessageStop)
        case metadata(Metadata)
        case error(StreamError)
        case unknown(eventType: String?, payload: JSONValue?)
    }

    struct MessageStart: Sendable, Codable, Hashable {
        public var role: Role

        public init(
            role: Role
        ) {
            self.role = role
        }
    }

    struct BlockStart: Sendable, Codable, Hashable {
        public var contentBlockIndex: Int
        public var start: BlockStartValue

        public init(
            contentBlockIndex: Int,
            start: BlockStartValue
        ) {
            self.contentBlockIndex = contentBlockIndex
            self.start = start
        }
    }

    enum BlockStartValue: Sendable, Codable, Hashable {
        case toolUse(ToolUseStart)
        case unknown(JSONValue)

        private enum CodingKeys: String, CodingKey {
            case toolUse
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            if let value = try container.decodeIfPresent(
                ToolUseStart.self,
                forKey: .toolUse
            ) {
                self = .toolUse(value)
                return
            }

            self = .unknown(
                try JSONValue(from: decoder)
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            switch self {
            case .toolUse(let value):
                var container = encoder.container(
                    keyedBy: CodingKeys.self
                )

                try container.encode(
                    value,
                    forKey: .toolUse
                )

            case .unknown(let value):
                try value.encode(
                    to: encoder
                )
            }
        }
    }

    struct ToolUseStart: Sendable, Codable, Hashable {
        public var toolUseId: String
        public var name: String

        public init(
            toolUseId: String,
            name: String
        ) {
            self.toolUseId = toolUseId
            self.name = name
        }
    }

    struct BlockDelta: Sendable, Codable, Hashable {
        public var contentBlockIndex: Int
        public var delta: BlockDeltaValue

        public init(
            contentBlockIndex: Int,
            delta: BlockDeltaValue
        ) {
            self.contentBlockIndex = contentBlockIndex
            self.delta = delta
        }
    }

    enum BlockDeltaValue: Sendable, Codable, Hashable {
        case text(String)
        case toolUse(ToolUseDelta)
        case unknown(JSONValue)

        private enum CodingKeys: String, CodingKey {
            case text
            case toolUse
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
                ToolUseDelta.self,
                forKey: .toolUse
            ) {
                self = .toolUse(value)
                return
            }

            self = .unknown(
                try JSONValue(from: decoder)
            )
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            switch self {
            case .text(let value):
                var container = encoder.container(
                    keyedBy: CodingKeys.self
                )

                try container.encode(
                    value,
                    forKey: .text
                )

            case .toolUse(let value):
                var container = encoder.container(
                    keyedBy: CodingKeys.self
                )

                try container.encode(
                    value,
                    forKey: .toolUse
                )

            case .unknown(let value):
                try value.encode(
                    to: encoder
                )
            }
        }
    }

    struct ToolUseDelta: Sendable, Codable, Hashable {
        public var input: String

        public init(
            input: String
        ) {
            self.input = input
        }
    }

    struct BlockStop: Sendable, Codable, Hashable {
        public var contentBlockIndex: Int

        public init(
            contentBlockIndex: Int
        ) {
            self.contentBlockIndex = contentBlockIndex
        }
    }

    struct MessageStop: Sendable, Codable, Hashable {
        public var stopReason: String?
        public var additionalModelResponseFields: JSONValue?

        public init(
            stopReason: String? = nil,
            additionalModelResponseFields: JSONValue? = nil
        ) {
            self.stopReason = stopReason
            self.additionalModelResponseFields = additionalModelResponseFields
        }
    }

    struct Metadata: Sendable, Codable, Hashable {
        public var usage: Usage?
        public var metrics: Metrics?

        public init(
            usage: Usage? = nil,
            metrics: Metrics? = nil
        ) {
            self.usage = usage
            self.metrics = metrics
        }
    }

    struct Usage: Sendable, Codable, Hashable {
        public var inputTokens: Int?
        public var outputTokens: Int?
        public var totalTokens: Int?
        public var cacheReadInputTokens: Int?
        public var cacheWriteInputTokens: Int?

        public init(
            inputTokens: Int? = nil,
            outputTokens: Int? = nil,
            totalTokens: Int? = nil,
            cacheReadInputTokens: Int? = nil,
            cacheWriteInputTokens: Int? = nil
        ) {
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.totalTokens = totalTokens
            self.cacheReadInputTokens = cacheReadInputTokens
            self.cacheWriteInputTokens = cacheWriteInputTokens
        }
    }

    struct Metrics: Sendable, Codable, Hashable {
        public var latencyMs: Int?

        public init(
            latencyMs: Int? = nil
        ) {
            self.latencyMs = latencyMs
        }
    }

    struct StreamError: Sendable, Codable, Hashable {
        public var type: String
        public var message: String?

        public init(
            type: String,
            message: String? = nil
        ) {
            self.type = type
            self.message = message
        }
    }
}
