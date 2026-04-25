public struct BedrockModel: Sendable, Codable, Hashable {
    public var modelArn: String

    public init(
        modelArn: String
    ) {
        self.modelArn = modelArn
    }
}

