import Foundation

public enum AWSRegion {
    public static func resolve(
        profileName explicitProfileName: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> String {
        if let region = nonEmpty(
            environment["AWS_REGION"]
        ) ?? nonEmpty(
            environment["AWS_DEFAULT_REGION"]
        ) {
            return region
        }

        let profileName = explicitProfileName
            ?? nonEmpty(
                environment["AWS_PROFILE"]
            )
            ?? nonEmpty(
                environment["AWS_DEFAULT_PROFILE"]
            )
            ?? "default"

        let url = configURL(
            environment: environment
        )

        let file = try AWSConfigFile(
            url: url
        )

        guard let profile = file.profile(
            named: profileName
        ) else {
            throw AWSRegionError.missingConfigProfile(
                profileName: profileName,
                path: url.path
            )
        }

        guard let region = profile.value(
            "region"
        ) else {
            throw AWSRegionError.missingRegion(
                profileName: profileName,
                path: url.path
            )
        }

        return region
    }
}

private extension AWSRegion {
    static func configURL(
        environment: [String: String]
    ) -> URL {
        if let path = nonEmpty(
            environment["AWS_CONFIG_FILE"]
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
                "config",
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
