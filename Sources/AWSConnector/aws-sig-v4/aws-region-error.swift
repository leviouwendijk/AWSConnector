import Foundation

public enum AWSRegionError: Error, Sendable, LocalizedError {
    case missingConfigFile(String)
    case unreadableConfigFile(path: String, message: String)
    case missingConfigProfile(profileName: String, path: String)
    case missingRegion(profileName: String, path: String)

    public var errorDescription: String? {
        switch self {
        case .missingConfigFile(let path):
            return "Missing AWS config file at \(path)."

        case .unreadableConfigFile(let path, let message):
            return "Could not read AWS config file at \(path): \(message)"

        case .missingConfigProfile(let profileName, let path):
            return "Missing AWS config profile '\(profileName)' in \(path)."

        case .missingRegion(let profileName, let path):
            return "Missing AWS region in profile '\(profileName)' at \(path)."
        }
    }
}
