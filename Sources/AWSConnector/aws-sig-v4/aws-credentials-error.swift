import Foundation

public enum AWSCredentialsError: Error, Sendable, LocalizedError {
    case missingSharedCredentialsFile(String)
    case unreadableSharedCredentialsFile(path: String, message: String)
    case missingSharedCredentialsProfile(profileName: String, path: String)
    case missingProfileValue(profileName: String, key: String, path: String)

    public var errorDescription: String? {
        switch self {
        case .missingSharedCredentialsFile(let path):
            return "Missing AWS shared credentials file at \(path)."

        case .unreadableSharedCredentialsFile(let path, let message):
            return "Could not read AWS shared credentials file at \(path): \(message)"

        case .missingSharedCredentialsProfile(let profileName, let path):
            return "Missing AWS shared credentials profile '\(profileName)' in \(path)."

        case .missingProfileValue(let profileName, let key, let path):
            return "Missing AWS credential key '\(key)' in profile '\(profileName)' at \(path)."
        }
    }
}
