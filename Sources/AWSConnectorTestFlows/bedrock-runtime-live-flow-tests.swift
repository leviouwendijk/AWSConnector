import AWSConnector
import Foundation
import TestFlows

enum BedrockRuntimeLiveFlowTests {
    static let flows: [TestFlow] = [
        streamNovaMicroHelloQuote(),
    ]

    static func streamNovaMicroHelloQuote() -> TestFlow {
        TestFlow(
            "live-bedrock-runtime-nova-micro-hello-quote",
            tags: [
                "bedrock",
                "runtime",
                "stream",
                "live",
                "nova"
            ]
        ) {
            let env = ProcessInfo.processInfo.environment
            let region = try AWSRegion.resolve()
            let credentials = try AWSCredentials.resolve()

            let modelIdentifier = try await novaMicroModelIdentifier(
                region: region,
                credentials: credentials,
                env: env
            )

            let today = currentDateString()

            let request = Bedrock.Converse.Request(
                messages: [
                    .init(
                        role: .user,
                        content: [
                            .text(
                                """
                                Reply in exactly one short line. Include the word Hello, the date \(today), and this exact quote: "Small steps reveal the road."
                                """
                            )
                        ]
                    )
                ],
                inferenceConfig: .init(
                    maxTokens: 64,
                    temperature: 0.0,
                    topP: 0.9
                )
            )

            let runtime = BedrockRuntimeClient(
                region: region,
                credentials: credentials
            )

            let events = try await collect(
                runtime.converse.stream(
                    request,
                    modelIdentifier: modelIdentifier
                )
            )

            let text = streamedText(
                from: events
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            try Expect.notEmpty(
                text,
                "text"
            )

            try Expect.contains(
                text,
                "Hello",
                "text.hello"
            )

            try Expect.contains(
                text,
                today,
                "text.date"
            )

            try Expect.contains(
                text,
                "Small steps reveal the road",
                "text.quote"
            )

            return [
                .field(
                    "model",
                    modelIdentifier
                ),
                .field(
                    "text",
                    text
                )
            ]
        }
    }
}

private extension BedrockRuntimeLiveFlowTests {
    static func novaMicroModelIdentifier(
        region: String,
        credentials: AWSCredentials,
        env: [String: String]
    ) async throws -> String {
        if let explicit = nonEmpty(
            env["AWS_BEDROCK_LIVE_MODEL_ID"]
        ) {
            return explicit
        }

        if let explicit = nonEmpty(
            env["AWS_BEDROCK_NOVA_MICRO_PROFILE_ID"]
        ) {
            return explicit
        }

        let control = BedrockClient(
            region: region,
            credentials: credentials
        )

        let profiles = try await control.inferenceProfiles.list(
            .init(
                maxResults: 100,
                typeEquals: "SYSTEM_DEFINED"
            )
        )

        if let profile = profiles.inferenceProfileSummaries.first(
            where: { summary in
                summary.status == "ACTIVE"
                    && summary.inferenceProfileId.contains(
                        "amazon.nova-micro"
                    )
            }
        ) {
            return profile.inferenceProfileId
        }

        return "eu.amazon.nova-micro-v1:0"
    }

    static func collect(
        _ stream: AsyncThrowingStream<Bedrock.Converse.StreamEvent, Error>
    ) async throws -> [Bedrock.Converse.StreamEvent] {
        var events: [Bedrock.Converse.StreamEvent] = []

        for try await event in stream {
            events.append(
                event
            )
        }

        return events
    }

    static func streamedText(
        from events: [Bedrock.Converse.StreamEvent]
    ) -> String {
        events.reduce(
            into: ""
        ) { result, event in
            guard case .blockDelta(let delta) = event,
                  case .text(let text) = delta.delta else {
                return
            }

            result.append(
                text
            )
        }
    }

    static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(
            identifier: .gregorian
        )
        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(
            from: Date()
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
}
