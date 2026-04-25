import AWSConnector
import Foundation

enum BedrockFlowSession {
    static func session(
        response: BedrockFlowHTTPResponse
    ) -> URLSession {
        BedrockFlowURLProtocol.configure(
            response: response
        )

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [
            BedrockFlowURLProtocol.self
        ]

        return URLSession(
            configuration: configuration
        )
    }

    static func runtimeClient(
        response: BedrockFlowHTTPResponse
    ) -> BedrockRuntimeClient {
        BedrockRuntimeClient(
            region: "eu-west-1",
            credentials: credentials(),
            session: session(
                response: response
            )
        )
    }

    static func client(
        response: BedrockFlowHTTPResponse
    ) -> BedrockRuntimeClient {
        runtimeClient(
            response: response
        )
    }

    static func bedrockClient(
        response: BedrockFlowHTTPResponse
    ) -> BedrockClient {
        BedrockClient(
            region: "eu-west-1",
            credentials: credentials(),
            session: session(
                response: response
            )
        )
    }

    static func credentials() -> AWSCredentials {
        .init(
            accessKeyId: "AKIATEST",
            secretAccessKey: "test-secret",
            sessionToken: "test-session"
        )
    }
}
