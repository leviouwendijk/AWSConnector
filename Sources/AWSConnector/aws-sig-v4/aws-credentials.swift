import Foundation
import Milieu
import Methods

public struct AWSCredentials: Sendable, Hashable {
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
        self.accessKeyId = try EnvironmentExtractor.value(
            .symbol(
                accessKeyIdSymbol
            )
        )
        self.secretAccessKey = try EnvironmentExtractor.value(
            .symbol(
                secretAccessKeySymbol
            )
        )

        if let sessionTokenSymbol {
            self.sessionToken = EnvironmentExtractor.optional(
                sessionTokenSymbol
            )
        } else {
            self.sessionToken = nil
        }
    }

    public init(
        accessKeyIdSymbol: EnvironmentExtractableKey,
        secretAccessKeySymbol: EnvironmentExtractableKey,
        sessionTokenSymbol: String? = nil
    ) throws {
        self.accessKeyId = try EnvironmentExtractor.value(
            accessKeyIdSymbol
        )
        self.secretAccessKey = try EnvironmentExtractor.value(
            secretAccessKeySymbol
        )
        self.sessionToken = EnvironmentExtractor.optional(
            sessionTokenSymbol
        )
    }
}

public extension AWSCredentials {
    static func resolve(
        profileName explicitProfileName: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Self {
        if let credentials = Self.environmentCredentials(
            environment
        ) {
            return credentials
        }

        return try Self.sharedCredentials(
            profileName: explicitProfileName,
            environment: environment
        )
    }
}

private extension AWSCredentials {
    static func environmentCredentials(
        _ environment: [String: String]
    ) -> Self? {
        guard let accessKeyId = nonEmpty(
            environment["AWS_ACCESS_KEY_ID"]
        ),
              let secretAccessKey = nonEmpty(
                environment["AWS_SECRET_ACCESS_KEY"]
              )
        else {
            return nil
        }

        return .init(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: nonEmpty(
                environment["AWS_SESSION_TOKEN"]
            )
        )
    }

    static func sharedCredentials(
        profileName explicitProfileName: String?,
        environment: [String: String]
    ) throws -> Self {
        let profileName = explicitProfileName
            ?? nonEmpty(
                environment["AWS_PROFILE"]
            )
            ?? nonEmpty(
                environment["AWS_DEFAULT_PROFILE"]
            )
            ?? "default"

        let url = sharedCredentialsURL(
            environment: environment
        )

        let file = try AWSSharedCredentialsFile(
            url: url
        )

        guard let profile = file.profile(
            named: profileName
        ) else {
            throw AWSCredentialsError.missingSharedCredentialsProfile(
                profileName: profileName,
                path: url.path
            )
        }

        guard let accessKeyId = profile.value(
            "aws_access_key_id"
        ) else {
            throw AWSCredentialsError.missingProfileValue(
                profileName: profileName,
                key: "aws_access_key_id",
                path: url.path
            )
        }

        guard let secretAccessKey = profile.value(
            "aws_secret_access_key"
        ) else {
            throw AWSCredentialsError.missingProfileValue(
                profileName: profileName,
                key: "aws_secret_access_key",
                path: url.path
            )
        }

        return .init(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: profile.value(
                "aws_session_token"
            )
        )
    }

    static func sharedCredentialsURL(
        environment: [String: String]
    ) -> URL {
        if let path = nonEmpty(
            environment["AWS_SHARED_CREDENTIALS_FILE"]
        ) {
            return URL(
                fileURLWithPath: expandedUserPath(
                    path
                )
            )
        }

        return FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(
                ".aws",
                isDirectory: true
            )
            .appendingPathComponent(
                "credentials",
                isDirectory: false
            )
    }

    static func nonEmpty(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    static func expandedUserPath(
        _ path: String
    ) -> String {
        guard path.hasPrefix("~/") else {
            return path
        }

        return FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(
                String(
                    path.dropFirst(2)
                )
            )
            .path
    }
}

// public struct AWSCredentials: Sendable {
//     public let accessKeyId: String
//     public let secretAccessKey: String
//     public let sessionToken: String?

//     public init(
//         accessKeyId: String,
//         secretAccessKey: String,
//         sessionToken: String? = nil
//     ) {
//         self.accessKeyId = accessKeyId
//         self.secretAccessKey = secretAccessKey
//         self.sessionToken = sessionToken
//     }

//     public init(
//         accessKeyIdSymbol: String,
//         secretAccessKeySymbol: String,
//         sessionTokenSymbol: String? = nil
//     ) throws {
//         self.accessKeyId = try EnvironmentExtractor.value(.symbol(accessKeyIdSymbol))
//         self.secretAccessKey = try EnvironmentExtractor.value(.symbol(secretAccessKeySymbol))
//         var sesTok: String?
//         sessionTokenSymbol.ifNotNil { value in 
//             sesTok = try? EnvironmentExtractor.value(.symbol(value))
//         }   
//         self.sessionToken = sesTok
//     }

//     public init(
//         accessKeyIdSymbol: EnvironmentExtractableKey,
//         secretAccessKeySymbol: EnvironmentExtractableKey,
//         sessionTokenSymbol: String? = nil
//     ) throws {
//         self.accessKeyId = try EnvironmentExtractor.value(accessKeyIdSymbol)
//         self.secretAccessKey = try EnvironmentExtractor.value(secretAccessKeySymbol)
//         self.sessionToken = EnvironmentExtractor.optional(sessionTokenSymbol)
//     }
// }
