import AWSConnector
import Foundation
import TestFlows

enum BedrockControlPlaneFlowTests {
    static func listFoundationModels() -> TestFlow {
        TestFlow(
            "bedrock-list-foundation-models",
            tags: [
                "bedrock",
                "models",
                "control-plane"
            ]
        ) {
            let response = """
            {
                "modelSummaries": [
                    {
                        "modelArn": "arn:aws:bedrock:eu-west-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0",
                        "modelId": "anthropic.claude-3-5-sonnet-20240620-v1:0",
                        "modelName": "Claude 3.5 Sonnet",
                        "providerName": "Anthropic",
                        "inputModalities": ["TEXT"],
                        "outputModalities": ["TEXT"],
                        "responseStreamingSupported": true,
                        "customizationsSupported": [],
                        "inferenceTypesSupported": ["ON_DEMAND"],
                        "modelLifecycle": {
                            "status": "ACTIVE"
                        }
                    }
                ]
            }
            """

            let client = BedrockFlowSession.bedrockClient(
                response: .init(
                    headers: [
                        "Content-Type": "application/json"
                    ],
                    body: Data(
                        response.utf8
                    )
                )
            )

            let result = try await client.models.list(
                .init(
                    byOutputModality: "TEXT",
                    byProvider: "Anthropic"
                )
            )

            try Expect.equal(
                result.modelSummaries.count,
                1,
                "modelCount"
            )

            let model = try Expect.notNil(
                result.modelSummaries.first,
                "model"
            )

            try Expect.equal(
                model.modelId,
                "anthropic.claude-3-5-sonnet-20240620-v1:0",
                "model.id"
            )

            try Expect.equal(
                model.providerName,
                "Anthropic",
                "model.provider"
            )

            try Expect.equal(
                model.responseStreamingSupported,
                true,
                "model.streaming"
            )

            let recorded = try Expect.notNil(
                BedrockFlowURLProtocol.recorded().first,
                "request"
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
                "/foundation-models",
                "path"
            )

            try Expect.equal(
                components.queryItems?.first {
                    $0.name == "byOutputModality"
                }?.value,
                "TEXT",
                "query.byOutputModality"
            )

            try Expect.equal(
                components.queryItems?.first {
                    $0.name == "byProvider"
                }?.value,
                "Anthropic",
                "query.byProvider"
            )

            try Expect.equal(
                recorded.request.value(
                    forHTTPHeaderField: "Host"
                ),
                "bedrock.eu-west-1.amazonaws.com",
                "host"
            )

            _ = try Expect.notNil(
                recorded.request.value(
                    forHTTPHeaderField: "Authorization"
                ),
                "authorization"
            )

            return [
                .field(
                    "model",
                    model.modelId
                )
            ]
        }
    }

    static func getInferenceProfile() -> TestFlow {
        TestFlow(
            "bedrock-get-inference-profile",
            tags: [
                "bedrock",
                "inference-profile",
                "control-plane"
            ]
        ) {
            let response = """
            {
                "createdAt": "2024-01-01T00:00:00Z",
                "description": "EU Claude 3.5 Sonnet system profile",
                "inferenceProfileArn": "arn:aws:bedrock:eu-west-1:123456789012:inference-profile/eu.anthropic.claude-3-5-sonnet-20240620-v1:0",
                "inferenceProfileId": "eu.anthropic.claude-3-5-sonnet-20240620-v1:0",
                "inferenceProfileName": "EU Claude 3.5 Sonnet",
                "models": [
                    {
                        "modelArn": "arn:aws:bedrock:eu-west-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
                    }
                ],
                "status": "ACTIVE",
                "type": "SYSTEM_DEFINED",
                "updatedAt": "2024-01-02T00:00:00Z"
            }
            """

            let client = BedrockFlowSession.bedrockClient(
                response: .init(
                    headers: [
                        "Content-Type": "application/json"
                    ],
                    body: Data(
                        response.utf8
                    )
                )
            )

            let profile = try await client.inferenceProfiles.get(
                systemProfileForModelIdentifier: "anthropic.claude-3-5-sonnet-20240620-v1:0",
                profileRegionPrefix: "eu"
            )

            try Expect.equal(
                profile.inferenceProfileId,
                "eu.anthropic.claude-3-5-sonnet-20240620-v1:0",
                "profile.id"
            )

            try Expect.equal(
                profile.status,
                "ACTIVE",
                "profile.status"
            )

            try Expect.equal(
                profile.type,
                "SYSTEM_DEFINED",
                "profile.type"
            )

            try Expect.equal(
                profile.models.count,
                1,
                "profile.models.count"
            )

            let model = try Expect.notNil(
                profile.models.first,
                "profile.model"
            )

            try Expect.contains(
                model.modelArn,
                "anthropic.claude-3-5-sonnet-20240620-v1:0",
                "profile.modelArn"
            )

            let recorded = try Expect.notNil(
                BedrockFlowURLProtocol.recorded().first,
                "request"
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
                "/inference-profiles/eu.anthropic.claude-3-5-sonnet-20240620-v1%3A0",
                "path"
            )

            try Expect.equal(
                recorded.request.value(
                    forHTTPHeaderField: "Host"
                ),
                "bedrock.eu-west-1.amazonaws.com",
                "host"
            )

            _ = try Expect.notNil(
                recorded.request.value(
                    forHTTPHeaderField: "Authorization"
                ),
                "authorization"
            )

            return [
                .field(
                    "profile",
                    profile.inferenceProfileId
                ),
                .field(
                    "model",
                    model.modelArn
                )
            ]
        }
    }
}
