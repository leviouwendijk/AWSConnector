import Foundation

public extension Bedrock {
    enum Models {}
}

public extension Bedrock.Models {
    struct ListRequest: Sendable, Hashable {
        public var byCustomizationType: String?
        public var byInferenceType: String?
        public var byOutputModality: String?
        public var byProvider: String?

        public init(
            byCustomizationType: String? = nil,
            byInferenceType: String? = nil,
            byOutputModality: String? = nil,
            byProvider: String? = nil
        ) {
            self.byCustomizationType = byCustomizationType
            self.byInferenceType = byInferenceType
            self.byOutputModality = byOutputModality
            self.byProvider = byProvider
        }
    }

    struct ListResponse: Sendable, Codable, Hashable {
        public var modelSummaries: [Summary]

        public init(
            modelSummaries: [Summary]
        ) {
            self.modelSummaries = modelSummaries
        }
    }

    struct Summary: Sendable, Codable, Hashable {
        public var modelArn: String
        public var modelId: String
        public var modelName: String?
        public var providerName: String?
        public var inputModalities: [String]?
        public var outputModalities: [String]?
        public var responseStreamingSupported: Bool?
        public var customizationsSupported: [String]?
        public var inferenceTypesSupported: [String]?
        public var modelLifecycle: Lifecycle?

        public init(
            modelArn: String,
            modelId: String,
            modelName: String? = nil,
            providerName: String? = nil,
            inputModalities: [String]? = nil,
            outputModalities: [String]? = nil,
            responseStreamingSupported: Bool? = nil,
            customizationsSupported: [String]? = nil,
            inferenceTypesSupported: [String]? = nil,
            modelLifecycle: Lifecycle? = nil
        ) {
            self.modelArn = modelArn
            self.modelId = modelId
            self.modelName = modelName
            self.providerName = providerName
            self.inputModalities = inputModalities
            self.outputModalities = outputModalities
            self.responseStreamingSupported = responseStreamingSupported
            self.customizationsSupported = customizationsSupported
            self.inferenceTypesSupported = inferenceTypesSupported
            self.modelLifecycle = modelLifecycle
        }
    }

    struct Lifecycle: Sendable, Codable, Hashable {
        public var status: String?

        public init(
            status: String? = nil
        ) {
            self.status = status
        }
    }
}
