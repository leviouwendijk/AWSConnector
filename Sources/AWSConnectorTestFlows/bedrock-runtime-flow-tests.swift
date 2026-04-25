import AWSConnector
import Foundation
import Primitives
import TestFlows

enum BedrockRuntimeFlowTests {
    static func requestSigningAndPath() -> TestFlow {
        TestFlow(
            "bedrock-request-signing-and-path",
            tags: [
                "bedrock",
                "stream",
                "request"
            ]
        ) {
            Step("stream empty response") {
                let client = BedrockFlowSession.client(
                    response: .init(
                        body: try BedrockFlowEventStream.stream(
                            BedrockFlowEventStream.event(
                                "messageStop",
                                payload: [
                                    "messageStop": .object([
                                        "stopReason": .string("end_turn")
                                    ])
                                ]
                            )
                        )
                    )
                )

                _ = try await collect(
                    client.converse.stream(
                        request(),
                        modelIdentifier: "anthropic.claude-3-5-sonnet-20241022-v2:0"
                    )
                )
            }

            Check("recorded request") {
                let recorded = try Expect.notNil(
                    BedrockFlowURLProtocol.recorded().first,
                    "request"
                )

                try Expect.equal(
                    recorded.request.httpMethod,
                    "POST",
                    "method"
                )

                let components = try Expect.notNil(
                    URLComponents(
                        url: try Expect.notNil(
                            recorded.request.url,
                            "url"
                        ),
                        resolvingAgainstBaseURL: false
                    ),
                    "urlComponents"
                )

                try Expect.equal(
                    components.percentEncodedPath,
                    "/model/anthropic.claude-3-5-sonnet-20241022-v2%3A0/converse-stream",
                    "path"
                )

                try Expect.equal(
                    recorded.request.value(
                        forHTTPHeaderField: "Host"
                    ),
                    "bedrock-runtime.eu-west-1.amazonaws.com",
                    "host"
                )

                try Expect.equal(
                    recorded.request.value(
                        forHTTPHeaderField: "Content-Type"
                    ),
                    "application/json",
                    "contentType"
                )

                try Expect.equal(
                    recorded.request.value(
                        forHTTPHeaderField: "Accept"
                    ),
                    "application/vnd.amazon.eventstream",
                    "accept"
                )

                _ = try Expect.notNil(
                    recorded.request.value(
                        forHTTPHeaderField: "Authorization"
                    ),
                    "authorization"
                )

                _ = try Expect.notNil(
                    recorded.request.value(
                        forHTTPHeaderField: "x-amz-content-sha256"
                    ),
                    "contentHash"
                )

                let body = try JSONDecoder().decode(
                    JSONValue.self,
                    from: recorded.body
                )

                try Expect.jsonValue(
                    body,
                    at: "messages.0.role",
                    equals: .string("user"),
                    "body"
                )

                try Expect.jsonValue(
                    body,
                    at: "messages.0.content.0.text",
                    equals: .string("hello"),
                    "body"
                )

                try Expect.jsonValue(
                    body,
                    at: "toolConfig.tools.0.toolSpec.name",
                    equals: .string("adapter_echo_tool"),
                    "body"
                )
            }
        }
    }

    static func streamTextAndMetadata() -> TestFlow {
        TestFlow(
            "bedrock-stream-text-and-metadata",
            tags: [
                "bedrock",
                "stream"
            ]
        ) {
            let body = try BedrockFlowEventStream.stream(
                BedrockFlowEventStream.event(
                    "messageStart",
                    payload: [
                        "messageStart": .object([
                            "role": .string("assistant")
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "contentBlockDelta",
                    payload: [
                        "contentBlockDelta": .object([
                            "contentBlockIndex": .int(0),
                            "delta": .object([
                                "text": .string("hello")
                            ])
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "metadata",
                    payload: [
                        "metadata": .object([
                            "usage": .object([
                                "inputTokens": .int(5),
                                "outputTokens": .int(7),
                                "totalTokens": .int(12)
                            ]),
                            "metrics": .object([
                                "latencyMs": .int(42)
                            ])
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "messageStop",
                    payload: [
                        "messageStop": .object([
                            "stopReason": .string("end_turn")
                        ])
                    ]
                )
            )

            let events = try await collect(
                BedrockFlowSession.client(
                    response: .init(
                        body: body
                    )
                ).converse.stream(
                    request(),
                    modelIdentifier: "test-model"
                )
            )

            try Expect.equal(
                events.count,
                4,
                "eventCount"
            )

            guard case .messageStart(let start) = events[0] else {
                throw TestFlowAssertionFailure(
                    label: "messageStart",
                    message: "first event was not messageStart"
                )
            }

            try Expect.equal(
                start.role,
                .assistant,
                "messageStart.role"
            )

            guard case .blockDelta(let delta) = events[1],
                  case .text(let text) = delta.delta else {
                throw TestFlowAssertionFailure(
                    label: "blockDelta",
                    message: "second event was not text delta"
                )
            }

            try Expect.equal(
                delta.contentBlockIndex,
                0,
                "delta.index"
            )
            try Expect.equal(
                text,
                "hello",
                "delta.text"
            )

            guard case .metadata(let metadata) = events[2] else {
                throw TestFlowAssertionFailure(
                    label: "metadata",
                    message: "third event was not metadata"
                )
            }

            try Expect.equal(
                metadata.usage?.inputTokens,
                5,
                "usage.input"
            )
            try Expect.equal(
                metadata.usage?.outputTokens,
                7,
                "usage.output"
            )
            try Expect.equal(
                metadata.usage?.totalTokens,
                12,
                "usage.total"
            )
            try Expect.equal(
                metadata.metrics?.latencyMs,
                42,
                "metrics.latency"
            )

            guard case .messageStop(let stop) = events[3] else {
                throw TestFlowAssertionFailure(
                    label: "messageStop",
                    message: "fourth event was not messageStop"
                )
            }

            try Expect.equal(
                stop.stopReason,
                "end_turn",
                "stopReason"
            )

            return [
                .field(
                    "events",
                    events.map {
                        String(
                            describing: $0
                        )
                    }.joined(
                        separator: ","
                    )
                )
            ]
        }
    }

    static func streamToolUse() -> TestFlow {
        TestFlow(
            "bedrock-stream-tool-use",
            tags: [
                "bedrock",
                "stream",
                "tools"
            ]
        ) {
            let body = try BedrockFlowEventStream.stream(
                BedrockFlowEventStream.event(
                    "contentBlockStart",
                    payload: [
                        "contentBlockStart": .object([
                            "contentBlockIndex": .int(1),
                            "start": .object([
                                "toolUse": .object([
                                    "toolUseId": .string("tool-1"),
                                    "name": .string("adapter_echo_tool")
                                ])
                            ])
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "contentBlockDelta",
                    payload: [
                        "contentBlockDelta": .object([
                            "contentBlockIndex": .int(1),
                            "delta": .object([
                                "toolUse": .object([
                                    "input": .string(#"{"text":"he"#)
                                ])
                            ])
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "contentBlockDelta",
                    payload: [
                        "contentBlockDelta": .object([
                            "contentBlockIndex": .int(1),
                            "delta": .object([
                                "toolUse": .object([
                                    "input": .string(#"llo"}"#)
                                ])
                            ])
                        ])
                    ]
                ),
                BedrockFlowEventStream.event(
                    "contentBlockStop",
                    payload: [
                        "contentBlockStop": .object([
                            "contentBlockIndex": .int(1)
                        ])
                    ]
                )
            )

            let events = try await collect(
                BedrockFlowSession.client(
                    response: .init(
                        body: body
                    )
                ).converse.stream(
                    request(),
                    modelIdentifier: "test-model"
                )
            )

            try Expect.equal(
                events.count,
                4,
                "eventCount"
            )

            guard case .blockStart(let start) = events[0],
                  case .toolUse(let tool) = start.start else {
                throw TestFlowAssertionFailure(
                    label: "toolUseStart",
                    message: "first event was not toolUse start"
                )
            }

            try Expect.equal(
                start.contentBlockIndex,
                1,
                "start.index"
            )
            try Expect.equal(
                tool.toolUseId,
                "tool-1",
                "tool.id"
            )
            try Expect.equal(
                tool.name,
                "adapter_echo_tool",
                "tool.name"
            )

            guard case .blockDelta(let firstDelta) = events[1],
                  case .toolUse(let firstToolDelta) = firstDelta.delta else {
                throw TestFlowAssertionFailure(
                    label: "firstToolDelta",
                    message: "second event was not toolUse delta"
                )
            }

            guard case .blockDelta(let secondDelta) = events[2],
                  case .toolUse(let secondToolDelta) = secondDelta.delta else {
                throw TestFlowAssertionFailure(
                    label: "secondToolDelta",
                    message: "third event was not toolUse delta"
                )
            }

            try Expect.equal(
                firstToolDelta.input,
                #"{"text":"he"#,
                "tool.delta.0"
            )
            try Expect.equal(
                secondToolDelta.input,
                #"llo"}"#,
                "tool.delta.1"
            )

            guard case .blockStop(let stop) = events[3] else {
                throw TestFlowAssertionFailure(
                    label: "toolUseStop",
                    message: "fourth event was not block stop"
                )
            }

            try Expect.equal(
                stop.contentBlockIndex,
                1,
                "stop.index"
            )

            return [
                .field(
                    "tool",
                    "\(tool.name) id=\(tool.toolUseId)"
                )
            ]
        }
    }

    static func serviceErrorEvent() -> TestFlow {
        TestFlow(
            "bedrock-stream-service-error-event",
            tags: [
                "bedrock",
                "stream",
                "errors"
            ]
        ) {
            let body = try BedrockFlowEventStream.stream(
                BedrockFlowEventStream.exception(
                    "throttlingException",
                    payload: [
                        "message": .string("slow down")
                    ]
                )
            )

            let client = BedrockFlowSession.client(
                response: .init(
                    body: body
                )
            )

            do {
                _ = try await collect(
                    client.converse.stream(
                        request(),
                        modelIdentifier: "test-model"
                    )
                )

                throw TestFlowAssertionFailure(
                    label: "serviceError",
                    message: "stream completed without throwing"
                )
            } catch let error as BedrockRuntimeError {
                guard case .service(let type, let message) = error else {
                    throw TestFlowAssertionFailure(
                        label: "serviceError",
                        message: "wrong Bedrock error",
                        actual: String(
                            describing: error
                        ),
                        expected: "service error"
                    )
                }

                try Expect.equal(
                    type,
                    "throttlingException",
                    "error.type"
                )
                try Expect.equal(
                    message,
                    "slow down",
                    "error.message"
                )

                return [
                    .field(
                        "error",
                        "\(type): \(message ?? "<nil>")"
                    )
                ]
            }
        }
    }

    static func httpErrorBody() -> TestFlow {
        TestFlow(
            "bedrock-stream-http-error-body",
            tags: [
                "bedrock",
                "stream",
                "errors"
            ]
        ) {
            let client = BedrockFlowSession.client(
                response: .init(
                    status: 429,
                    headers: [
                        "Content-Type": "application/json"
                    ],
                    body: Data(
                        #"{"message":"too many requests"}"#.utf8
                    )
                )
            )

            do {
                _ = try await collect(
                    client.converse.stream(
                        request(),
                        modelIdentifier: "test-model"
                    )
                )

                throw TestFlowAssertionFailure(
                    label: "httpError",
                    message: "stream completed without throwing"
                )
            } catch let error as BedrockRuntimeError {
                guard case .http(let status, let body) = error else {
                    throw TestFlowAssertionFailure(
                        label: "httpError",
                        message: "wrong Bedrock error",
                        actual: String(
                            describing: error
                        ),
                        expected: "http error"
                    )
                }

                try Expect.equal(
                    status,
                    429,
                    "http.status"
                )
                try Expect.contains(
                    body,
                    "too many requests",
                    "http.body"
                )

                return [
                    .value(
                        "status",
                        status
                    ),
                    .field(
                        "body",
                        body
                    )
                ]
            }
        }
    }
}

private extension BedrockRuntimeFlowTests {
    static func request() -> Bedrock.Converse.Request {
        .init(
            messages: [
                .init(
                    role: .user,
                    content: [
                        .text("hello")
                    ]
                )
            ],
            system: [
                .init(
                    text: "You are a test model."
                )
            ],
            inferenceConfig: .init(
                maxTokens: 128,
                temperature: 0.2,
                topP: 0.9,
                stopSequences: [
                    "STOP"
                ]
            ),
            toolConfig: .init(
                tools: [
                    .toolSpec(
                        .init(
                            name: "adapter_echo_tool",
                            description: "Echoes a value.",
                            inputSchema: .init(
                                json: .object([
                                    "type": .string("object"),
                                    "properties": .object([
                                        "text": .object([
                                            "type": .string("string")
                                        ])
                                    ]),
                                    "required": .array([
                                        .string("text")
                                    ])
                                ])
                            )
                        )
                    )
                ]
            )
        )
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
}
