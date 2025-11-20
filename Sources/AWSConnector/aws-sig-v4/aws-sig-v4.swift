import Foundation
import CryptoKit

public struct AWSSigV4Signer: Sendable {
    public let credentials: AWSCredentials
    public let region: String
    public let service: String

    public init(
        credentials: AWSCredentials,
        region: String,
        service: String
    ) {
        self.credentials = credentials
        self.region = region
        self.service = service
    }

    /// Mutates the request in place: adds x-amz-date, host, x-amz-security-token (if any),
    /// x-amz-content-sha256, and Authorization.
    public func sign(
        request: inout URLRequest,
        body: Data,
        date: Date = Date()
    ) throws {
        guard let url = request.url else {
            throw SigV4Error.missingURL
        }

        let (amzDate, dateStamp) = makeTimestamps(from: date)

        let payloadHashHex = sha256Hex(of: body)

        // Start from existing headers, but normalize on lowercase keys for canonicalization.
        var canonicalHeaderMap: [String: String] = [:]

        if let existing = request.allHTTPHeaderFields {
            for (name, value) in existing {
                let lower = name.lowercased()
                canonicalHeaderMap[lower] = trimmedHeaderValue(value)
            }
        }

        if let host = url.host {
            canonicalHeaderMap["host"] = host
        }

        canonicalHeaderMap["x-amz-date"] = amzDate
        canonicalHeaderMap["x-amz-content-sha256"] = payloadHashHex

        if let token = credentials.sessionToken {
            canonicalHeaderMap["x-amz-security-token"] = trimmedHeaderValue(token)
        }

        let signedHeaderNames = canonicalHeaderMap.keys.sorted()
        let canonicalHeadersString = signedHeaderNames
            .map { name in
                let value = canonicalHeaderMap[name] ?? ""
                return "\(name):\(value)\n"
            }
            .joined()

        let signedHeaders = signedHeaderNames.joined(separator: ";")

        let method = request.httpMethod ?? "GET"

        let path: String = {
            let p = url.path
            return p.isEmpty ? "/" : p
        }()

        let canonicalQuery = canonicalQueryString(from: url)

        let canonicalRequest = [
            method,
            path,
            canonicalQuery,
            canonicalHeadersString,
            signedHeaders,
            payloadHashHex
        ].joined(separator: "\n")

        let canonicalRequestHashHex = sha256Hex(of: Data(canonicalRequest.utf8))

        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"

        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            canonicalRequestHashHex
        ].joined(separator: "\n")

        let signingKey = try deriveSigningKey(
            secretKey: credentials.secretAccessKey,
            dateStamp: dateStamp,
            region: region,
            service: service
        )

        let signatureHex = hmacSHA256Hex(
            key: signingKey,
            data: Data(stringToSign.utf8)
        )

        let authorizationHeader = """
        AWS4-HMAC-SHA256 \
        Credential=\(credentials.accessKeyId)/\(credentialScope), \
        SignedHeaders=\(signedHeaders), \
        Signature=\(signatureHex)
        """

        // Write back headers to the URLRequest (using the canonical map + any original headers).
        var newHeaders: [String: String] = request.allHTTPHeaderFields ?? [:]
        for (lower, value) in canonicalHeaderMap {
            // Use the lowercase key directly; HTTP header names are case-insensitive.
            newHeaders[lower] = value
        }
        newHeaders["Authorization"] = authorizationHeader.trimmingCharacters(in: .whitespaces)

        request.allHTTPHeaderFields = newHeaders
    }
}

private func makeTimestamps(from date: Date) -> (amzDate: String, dateStamp: String) {
    let amzFormatter = DateFormatter()
    amzFormatter.calendar = Calendar(identifier: .gregorian)
    amzFormatter.locale = Locale(identifier: "en_US_POSIX")
    amzFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    amzFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"

    let dateFormatter = DateFormatter()
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyyMMdd"

    let amzDate = amzFormatter.string(from: date)
    let dateStamp = dateFormatter.string(from: date)
    return (amzDate, dateStamp)
}

private func trimmedHeaderValue(_ value: String) -> String {
    // Collapse multiple spaces into one, and trim leading/trailing whitespace.
    let components = value.split(whereSeparator: { $0.isWhitespace })
    return components.joined(separator: " ")
}

private func canonicalQueryString(from url: URL) -> String {
    guard let query = url.query, !query.isEmpty else {
        return ""
    }

    // Simple implementation: split on "&" and "=", sort by key, and re-encode.
    // For SES SendEmail we typically have no query params, so this is mostly unused.
    let items = query.split(separator: "&").compactMap { pair -> (String, String)? in
        let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = String(parts[0])
        let value = parts.count > 1 ? String(parts[1]) : ""
        return (name, value)
    }

    let sorted = items.sorted { $0.0 < $1.0 }

    return sorted
        .map { name, value in
            let encodedName = awsPercentEncode(name)
            let encodedValue = awsPercentEncode(value)
            return "\(encodedName)=\(encodedValue)"
        }
        .joined(separator: "&")
}

private func awsPercentEncode(_ value: String) -> String {
    // AWS percent-encoding: encode everything except unreserved chars.
    let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    var encoded = ""

    for byte in value.utf8 {
        let scalar = UnicodeScalar(byte)
        let character = Character(scalar)

        if unreserved.contains(character) {
            encoded.append(character)
        } else {
            encoded.append(String(format: "%%%02X", byte))
        }
    }

    return encoded
}

private func sha256Hex(of data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}

private func hmacSHA256(
    key: Data,
    data: Data
) -> Data {
    let keySym = SymmetricKey(data: key)
    let mac = HMAC<SHA256>.authenticationCode(for: data, using: keySym)
    return Data(mac)
}

private func hmacSHA256Hex(
    key: Data,
    data: Data
) -> String {
    let mac = hmacSHA256(key: key, data: data)
    return mac.map { String(format: "%02x", $0) }.joined()
}

private func deriveSigningKey(
    secretKey: String,
    dateStamp: String,
    region: String,
    service: String
) throws -> Data {
    let kSecret = Data(("AWS4" + secretKey).utf8)
    let kDate = hmacSHA256(key: kSecret, data: Data(dateStamp.utf8))
    let kRegion = hmacSHA256(key: kDate, data: Data(region.utf8))
    let kService = hmacSHA256(key: kRegion, data: Data(service.utf8))
    let kSigning = hmacSHA256(key: kService, data: Data("aws4_request".utf8))
    return kSigning
}
