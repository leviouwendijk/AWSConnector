import Foundation

public extension Bedrock {
    enum InferenceProfiles {}
}

public extension Bedrock.InferenceProfiles {
    struct Profile: Sendable, Codable, Hashable {
        public var createdAt: String?
        public var description: String?
        public var inferenceProfileArn: String
        public var inferenceProfileId: String
        public var inferenceProfileName: String
        public var models: [BedrockModel]
        public var status: String?
        public var type: String?
        public var updatedAt: String?

        public init(
            createdAt: String? = nil,
            description: String? = nil,
            inferenceProfileArn: String,
            inferenceProfileId: String,
            inferenceProfileName: String,
            models: [BedrockModel],
            status: String? = nil,
            type: String? = nil,
            updatedAt: String? = nil
        ) {
            self.createdAt = createdAt
            self.description = description
            self.inferenceProfileArn = inferenceProfileArn
            self.inferenceProfileId = inferenceProfileId
            self.inferenceProfileName = inferenceProfileName
            self.models = models
            self.status = status
            self.type = type
            self.updatedAt = updatedAt
        }
    }

    struct ListRequest: Sendable, Hashable {
        public var maxResults: Int?
        public var nextToken: String?
        public var typeEquals: String?

        public init(
            maxResults: Int? = nil,
            nextToken: String? = nil,
            typeEquals: String? = nil
        ) {
            self.maxResults = maxResults
            self.nextToken = nextToken
            self.typeEquals = typeEquals
        }
    }

    struct ListResponse: Sendable, Codable, Hashable {
        public var inferenceProfileSummaries: [Summary]
        public var nextToken: String?

        public init(
            inferenceProfileSummaries: [Summary],
            nextToken: String? = nil
        ) {
            self.inferenceProfileSummaries = inferenceProfileSummaries
            self.nextToken = nextToken
        }
    }

    struct Summary: Sendable, Codable, Hashable {
        public var inferenceProfileArn: String
        public var inferenceProfileId: String
        public var inferenceProfileName: String
        public var models: [BedrockModel]
        public var status: String
        public var type: String

        public init(
            inferenceProfileArn: String,
            inferenceProfileId: String,
            inferenceProfileName: String,
            models: [BedrockModel],
            status: String,
            type: String
        ) {
            self.inferenceProfileArn = inferenceProfileArn
            self.inferenceProfileId = inferenceProfileId
            self.inferenceProfileName = inferenceProfileName
            self.models = models
            self.status = status
            self.type = type
        }
    }
}
