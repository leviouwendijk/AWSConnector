import Foundation
import Milieu
import Methods

public struct AWSCredentials: Sendable {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?

    public init(
        accessKeyId: String,
        secretAccessKey: String,
        sessionToken: String? = nil
    ) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
    }

    public init(
        accessKeyIdSymbol: String,
        secretAccessKeySymbol: String,
        sessionTokenSymbol: String? = nil
    ) throws {
        self.accessKeyId = try EnvironmentExtractor.value(.symbol(accessKeyIdSymbol))
        self.secretAccessKey = try EnvironmentExtractor.value(.symbol(secretAccessKeySymbol))
        var sesTok: String?
        sessionTokenSymbol.ifNotNil { value in 
            sesTok = try? EnvironmentExtractor.value(.symbol(value))
        }   
        self.sessionToken = sesTok
    }

    public init(
        accessKeyIdSymbol: EnvironmentExtractableKey,
        secretAccessKeySymbol: EnvironmentExtractableKey,
        sessionTokenSymbol: String? = nil
    ) throws {
        self.accessKeyId = try EnvironmentExtractor.value(accessKeyIdSymbol)
        self.secretAccessKey = try EnvironmentExtractor.value(secretAccessKeySymbol)
        self.sessionToken = EnvironmentExtractor.optional(sessionTokenSymbol)
    }
}
