import Foundation

struct AWSSharedCredentialsFile: Sendable, Hashable {
    var profiles: [String: AWSSharedCredentialsProfile]

    init(
        url: URL
    ) throws {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            throw AWSCredentialsError.missingSharedCredentialsFile(
                url.path
            )
        }

        let contents: String

        do {
            contents = try String(
                contentsOf: url,
                encoding: .utf8
            )
        } catch {
            throw AWSCredentialsError.unreadableSharedCredentialsFile(
                path: url.path,
                message: error.localizedDescription
            )
        }

        self.profiles = Self.parse(
            contents
        )
    }

    func profile(
        named name: String
    ) -> AWSSharedCredentialsProfile? {
        profiles[name]
            ?? profiles["profile \(name)"]
    }
}

struct AWSSharedCredentialsProfile: Sendable, Hashable {
    var name: String
    var values: [String: String]

    func value(
        _ key: String
    ) -> String? {
        values[key.lowercased()]
    }
}

private extension AWSSharedCredentialsFile {
    static func parse(
        _ contents: String
    ) -> [String: AWSSharedCredentialsProfile] {
        var profiles: [String: AWSSharedCredentialsProfile] = [:]
        var currentName: String?
        var currentValues: [String: String] = [:]

        func flush() {
            guard let currentName else {
                return
            }

            profiles[currentName] = .init(
                name: currentName,
                values: currentValues
            )
        }

        for rawLine in contents.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ) {
            let line = strippedComment(
                String(
                    rawLine
                )
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !line.isEmpty else {
                continue
            }

            if line.hasPrefix("["),
               line.hasSuffix("]") {
                flush()

                currentName = String(
                    line.dropFirst().dropLast()
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                currentValues = [:]

                continue
            }

            guard currentName != nil,
                  let equals = line.firstIndex(
                    of: "="
                  )
            else {
                continue
            }

            let key = String(
                line[..<equals]
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

            let value = String(
                line[line.index(after: equals)...]
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            currentValues[key] = unquoted(
                value
            )
        }

        flush()

        return profiles
    }

    static func strippedComment(
        _ line: String
    ) -> String {
        var inSingleQuote = false
        var inDoubleQuote = false

        for index in line.indices {
            let character = line[index]

            if character == "'",
               !inDoubleQuote {
                inSingleQuote.toggle()
                continue
            }

            if character == "\"",
               !inSingleQuote {
                inDoubleQuote.toggle()
                continue
            }

            guard !inSingleQuote,
                  !inDoubleQuote,
                  character == "#" || character == ";"
            else {
                continue
            }

            return String(
                line[..<index]
            )
        }

        return line
    }

    static func unquoted(
        _ value: String
    ) -> String {
        if value.count >= 2,
           value.hasPrefix("\""),
           value.hasSuffix("\"") {
            return String(
                value.dropFirst().dropLast()
            )
        }

        if value.count >= 2,
           value.hasPrefix("'"),
           value.hasSuffix("'") {
            return String(
                value.dropFirst().dropLast()
            )
        }

        return value
    }
}
