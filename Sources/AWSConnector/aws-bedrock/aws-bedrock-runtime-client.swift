import Foundation
import Primitives

public struct BedrockRuntimeClient: Sendable {
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
        self.host = host ?? "bedrock-runtime.\(region).amazonaws.com"
        self.session = session
    }

    public var converse: BedrockRuntimeConverseClient {
        .init(
            runtime: self
        )
    }

    public static func resolve() throws -> Self {
        BedrockRuntimeClient(
            region: try AWSRegion.resolve(),
            credentials: try AWSCredentials.resolve()
        )
    }
}

public struct BedrockRuntimeConverseClient: Sendable {
    public let runtime: BedrockRuntimeClient

    public init(
        runtime: BedrockRuntimeClient
    ) {
        self.runtime = runtime
    }

    public func stream(
        _ request: Bedrock.Converse.Request,
        modelIdentifier: String
    ) -> AsyncThrowingStream<Bedrock.Converse.StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let urlRequest = try runtime.request(
                        path: "/model/\(bedrockPathEncode(modelIdentifier))/converse-stream",
                        body: try runtime.json.encoder.encode(
                            request
                        )
                    )

                    let (bytes, response) = try await runtime.session.bytes(
                        for: urlRequest
                    )

                    guard let http = response as? HTTPURLResponse else {
                        throw BedrockRuntimeError.invalidResponse
                    }

                    guard http.statusCode == 200 else {
                        throw BedrockRuntimeError.http(
                            status: http.statusCode,
                            body: try await runtime.collect(
                                bytes,
                                limit: 16_384
                            )
                        )
                    }

                    var decoder = AWSEventStreamDecoder()

                    for try await byte in bytes {
                        if Task.isCancelled {
                            continuation.finish(
                                throwing: CancellationError()
                            )
                            return
                        }

                        let messages = try decoder.append(
                            byte
                        )

                        for message in messages {
                            let event = try decode(
                                message
                            )

                            switch event {
                            case .error(let error):
                                continuation.finish(
                                    throwing: BedrockRuntimeError.service(
                                        type: error.type,
                                        message: error.message
                                    )
                                )
                                return

                            default:
                                continuation.yield(
                                    event
                                )
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(
                        throwing: error
                    )
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private extension BedrockRuntimeClient {
    var json: BedrockRuntimeJSON {
        .init()
    }

    func request(
        path: String,
        body: Data
    ) throws -> URLRequest {
        let urlString = "https://\(host)\(path)"

        guard let url = URL(
            string: urlString
        ) else {
            throw BedrockRuntimeError.invalidURL(
                urlString
            )
        }

        var request = URLRequest(
            url: url
        )
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "application/vnd.amazon.eventstream",
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
            body: body
        )

        return request
    }

    func collect(
        _ bytes: URLSession.AsyncBytes,
        limit: Int
    ) async throws -> String {
        var data = Data()

        for try await byte in bytes {
            guard data.count < limit else {
                break
            }

            data.append(
                byte
            )
        }

        return String(
            data: data,
            encoding: .utf8
        ) ?? "<non-UTF8 body>"
    }
}

private extension BedrockRuntimeConverseClient {
    func decode(
        _ message: AWSEventStreamMessage
    ) throws -> Bedrock.Converse.StreamEvent {
        if message.messageType == "exception" {
            return .error(
                .init(
                    type: message.exceptionType ?? message.eventType ?? "BedrockRuntimeException",
                    message: errorMessage(
                        from: message.payload
                    )
                )
            )
        }

        guard !message.payload.isEmpty else {
            return .unknown(
                eventType: message.eventType,
                payload: nil
            )
        }

        switch message.eventType {
        case "messageStart":
            return .messageStart(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.MessageStart.self,
                    from: unwrapped(
                        message.payload,
                        key: "messageStart"
                    )
                )
            )

        case "contentBlockStart":
            return .blockStart(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.BlockStart.self,
                    from: unwrapped(
                        message.payload,
                        key: "contentBlockStart"
                    )
                )
            )

        case "contentBlockDelta":
            return .blockDelta(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.BlockDelta.self,
                    from: unwrapped(
                        message.payload,
                        key: "contentBlockDelta"
                    )
                )
            )

        case "contentBlockStop":
            return .blockStop(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.BlockStop.self,
                    from: unwrapped(
                        message.payload,
                        key: "contentBlockStop"
                    )
                )
            )

        case "messageStop":
            return .messageStop(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.MessageStop.self,
                    from: unwrapped(
                        message.payload,
                        key: "messageStop"
                    )
                )
            )

        case "metadata":
            return .metadata(
                try runtime.json.decoder.decode(
                    Bedrock.Converse.Metadata.self,
                    from: unwrapped(
                        message.payload,
                        key: "metadata"
                    )
                )
            )

        default:
            return .unknown(
                eventType: message.eventType,
                payload: try? runtime.json.decoder.decode(
                    JSONValue.self,
                    from: message.payload
                )
            )
        }
    }

    func unwrapped(
        _ data: Data,
        key: String
    ) throws -> Data {
        if let object = try? runtime.json.decoder.decode(
            [String: JSONValue].self,
            from: data
        ),
           case .object(let nested)? = object[key] {
            return try runtime.json.encoder.encode(
                JSONValue.object(nested)
            )
        }

        return data
    }

    func errorMessage(
        from data: Data
    ) -> String? {
        guard !data.isEmpty,
              let object = try? runtime.json.decoder.decode(
                [String: JSONValue].self,
                from: data
              )
        else {
            return nil
        }

        if case .string(let value)? = object["message"] {
            return value
        }

        if case .string(let value)? = object["Message"] {
            return value
        }

        return String(
            data: data,
            encoding: .utf8
        )
    }
}

private struct BedrockRuntimeJSON: Sendable {
    var encoder: JSONEncoder {
        JSONEncoder()
    }

    var decoder: JSONDecoder {
        JSONDecoder()
    }
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
