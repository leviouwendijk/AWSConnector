import Foundation

public struct BedrockClient: Sendable {
    public let region: String
    public let credentials: AWSCredentials
    public let host: String
    public let session: URLSession

    public init(
        region: String,
        credentials: AWSCredentials,
        host: String? = nil,
        session: URLSession = .shared
    ) {
        self.region = region
        self.credentials = credentials
        self.host = host ?? "bedrock.\(region).amazonaws.com"
        self.session = session
    }

    public var models: BedrockModelsClient {
        .init(
            bedrock: self
        )
    }

    public var inferenceProfiles: BedrockInferenceProfilesClient {
        .init(
            bedrock: self
        )
    }

    public static func resolve() throws -> Self {
        BedrockClient(
            region: try AWSRegion.resolve(),
            credentials: try AWSCredentials.resolve()
        )
    }
}

public struct BedrockModelsClient: Sendable {
    public let bedrock: BedrockClient

    public init(
        bedrock: BedrockClient
    ) {
        self.bedrock = bedrock
    }

    public func list(
        _ request: Bedrock.Models.ListRequest = .init()
    ) async throws -> Bedrock.Models.ListResponse {
        var queryItems: [URLQueryItem] = []

        if let value = request.byCustomizationType {
            queryItems.append(
                .init(
                    name: "byCustomizationType",
                    value: value
                )
            )
        }

        if let value = request.byInferenceType {
            queryItems.append(
                .init(
                    name: "byInferenceType",
                    value: value
                )
            )
        }

        if let value = request.byOutputModality {
            queryItems.append(
                .init(
                    name: "byOutputModality",
                    value: value
                )
            )
        }

        if let value = request.byProvider {
            queryItems.append(
                .init(
                    name: "byProvider",
                    value: value
                )
            )
        }

        return try await bedrock.send(
            path: "/foundation-models",
            queryItems: queryItems,
            response: Bedrock.Models.ListResponse.self
        )
    }
}

public struct BedrockInferenceProfilesClient: Sendable {
    public let bedrock: BedrockClient

    public init(
        bedrock: BedrockClient
    ) {
        self.bedrock = bedrock
    }

    public func get(
        identifier: String
    ) async throws -> Bedrock.InferenceProfiles.Profile {
        try await bedrock.send(
            path: "/inference-profiles/\(bedrockPathEncode(identifier))",
            response: Bedrock.InferenceProfiles.Profile.self
        )
    }

    public func get(
        systemProfileForModelIdentifier modelIdentifier: String,
        profileRegionPrefix: String
    ) async throws -> Bedrock.InferenceProfiles.Profile {
        try await get(
            identifier: "\(profileRegionPrefix).\(modelIdentifier)"
        )
    }

    public func list(
        _ request: Bedrock.InferenceProfiles.ListRequest = .init()
    ) async throws -> Bedrock.InferenceProfiles.ListResponse {
        var queryItems: [URLQueryItem] = []

        if let value = request.maxResults {
            queryItems.append(
                .init(
                    name: "maxResults",
                    value: String(value)
                )
            )
        }

        if let value = request.nextToken {
            queryItems.append(
                .init(
                    name: "nextToken",
                    value: value
                )
            )
        }

        if let value = request.typeEquals {
            queryItems.append(
                .init(
                    name: "typeEquals",
                    value: value
                )
            )
        }

        return try await bedrock.send(
            path: "/inference-profiles",
            queryItems: queryItems,
            response: Bedrock.InferenceProfiles.ListResponse.self
        )
    }
}

public enum BedrockControlPlaneError: Error, Sendable, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case http(status: Int, body: String)
    case decode(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid Bedrock URL: \(value)."

        case .invalidResponse:
            return "Invalid Bedrock HTTP response."

        case .http(let status, let body):
            return "Bedrock HTTP error \(status): \(body)"

        case .decode(let message):
            return "Failed to decode Bedrock response: \(message)"
        }
    }
}

private extension BedrockClient {
    func send<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        response: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            queryItems: queryItems
        )

        let (data, urlResponse) = try await session.data(
            for: request
        )

        guard let http = urlResponse as? HTTPURLResponse else {
            throw BedrockControlPlaneError.invalidResponse
        }

        guard http.statusCode == 200 else {
            throw BedrockControlPlaneError.http(
                status: http.statusCode,
                body: String(
                    data: data,
                    encoding: .utf8
                ) ?? "<non-UTF8 body>"
            )
        }

        do {
            return try JSONDecoder().decode(
                Response.self,
                from: data
            )
        } catch {
            throw BedrockControlPlaneError.decode(
                error.localizedDescription
            )
        }
    }

    func makeRequest(
        path: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        let query = percentEncodedQuery(
            queryItems
        )
        let suffix = query.isEmpty ? "" : "?\(query)"
        let urlString = "https://\(host)\(path)\(suffix)"

        guard let url = URL(
            string: urlString
        ) else {
            throw BedrockControlPlaneError.invalidURL(
                urlString
            )
        }

        var request = URLRequest(
            url: url
        )
        request.httpMethod = "GET"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            host,
            forHTTPHeaderField: "Host"
        )

        let signer = AWSSigV4Signer(
            credentials: credentials,
            region: region,
            service: "bedrock"
        )

        try signer.sign(
            request: &request,
            body: Data()
        )

        return request
    }
}

private func percentEncodedQuery(
    _ items: [URLQueryItem]
) -> String {
    guard !items.isEmpty else {
        return ""
    }

    var components = URLComponents()
    components.queryItems = items

    return components.percentEncodedQuery ?? ""
}

private func bedrockPathEncode(
    _ value: String
) -> String {
    let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    var encoded = ""

    for byte in value.utf8 {
        let scalar = UnicodeScalar(byte)
        let character = Character(scalar)

        if unreserved.contains(character) {
            encoded.append(
                character
            )
        } else {
            encoded.append(
                String(
                    format: "%%%02X",
                    byte
                )
            )
        }
    }

    return encoded
}

public extension BedrockModelsClient {
    func listAll(
        _ request: Bedrock.Models.ListRequest = .init()
    ) async throws -> [Bedrock.Models.Summary] {
        try await list(
            request
        ).modelSummaries
    }
}

public extension BedrockInferenceProfilesClient {
    func listAll(
        _ request: Bedrock.InferenceProfiles.ListRequest = .init()
    ) async throws -> [Bedrock.InferenceProfiles.Summary] {
        var summaries: [Bedrock.InferenceProfiles.Summary] = []
        var nextToken = request.nextToken

        repeat {
            let response = try await list(
                .init(
                    maxResults: request.maxResults,
                    nextToken: nextToken,
                    typeEquals: request.typeEquals
                )
            )

            summaries.append(
                contentsOf: response.inferenceProfileSummaries
            )

            nextToken = response.nextToken
        } while nextToken != nil

        return summaries
    }
}
