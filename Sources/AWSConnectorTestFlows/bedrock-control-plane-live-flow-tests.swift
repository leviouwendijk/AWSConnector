import AWSConnector
import Foundation
import TestFlows

enum BedrockControlPlaneLiveFlowTests {
    static let flows: [TestFlow] = [
        listFoundationModels(),
        getInferenceProfile(),
    ]

    static func listFoundationModels() -> TestFlow {
        TestFlow(
            "live-bedrock-list-foundation-models",
            tags: [
                "bedrock",
                "models",
                "control-plane",
                "live"
            ]
        ) {
            let client = try liveClient()

            let response = try await client.models.list(
                .init(
                    byOutputModality: "TEXT"
                )
            )

            try Expect.notEmpty(
                response.modelSummaries,
                "models"
            )

            return [
                .value(
                    "count",
                    response.modelSummaries.count
                ),
                .field(
                    "first",
                    response.modelSummaries.first?.modelId ?? "<none>"
                )
            ]
        }
    }

    static func getInferenceProfile() -> TestFlow {
        TestFlow(
            "live-bedrock-get-inference-profile",
            tags: [
                "bedrock",
                "inference-profile",
                "control-plane",
                "live"
            ]
        ) {
            let client = try liveClient()
            let env = ProcessInfo.processInfo.environment

            let requestedModelIdentifier = env["AWS_BEDROCK_PROFILE_MODEL_ID"]

            let summaries = try await client.inferenceProfiles.list(
                .init(
                    maxResults: 100,
                    typeEquals: "SYSTEM_DEFINED"
                )
            )

            try Expect.notEmpty(
                summaries.inferenceProfileSummaries,
                "profiles"
            )

            let selected = try Expect.notNil(
                summaries.inferenceProfileSummaries.first { summary in
                    guard let requestedModelIdentifier else {
                        return summary.status == "ACTIVE"
                    }

                    return summary.models.contains { model in
                        model.modelArn.contains(
                            requestedModelIdentifier
                        )
                    }
                } ?? summaries.inferenceProfileSummaries.first,
                "selectedProfile"
            )

            let profile = try await client.inferenceProfiles.get(
                identifier: selected.inferenceProfileId
            )

            try Expect.equal(
                profile.status,
                "ACTIVE",
                "profile.status"
            )

            try Expect.notEmpty(
                profile.models,
                "profile.models"
            )

            return [
                .field(
                    "profile",
                    profile.inferenceProfileId
                ),
                .field(
                    "type",
                    profile.type ?? "<nil>"
                ),
                .value(
                    "models",
                    profile.models.count
                )
            ]
        }
    }
}

private extension BedrockControlPlaneLiveFlowTests {
    static func liveClient() throws -> BedrockClient {
        BedrockClient(
            region: try AWSRegion.resolve(),
            credentials: try AWSCredentials.resolve()
        )
    }
}
