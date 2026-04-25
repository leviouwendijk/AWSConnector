import TestFlows

private let live = true

struct AWSConnectorTestSuite: TestFlowRegistry {
    static let title = "AWSConnector flow tests"

    static let flows: [TestFlow] = [
        BedrockRuntimeFlowTests.requestSigningAndPath(),
        BedrockRuntimeFlowTests.streamTextAndMetadata(),
        BedrockRuntimeFlowTests.streamToolUse(),
        BedrockRuntimeFlowTests.serviceErrorEvent(),
        BedrockRuntimeFlowTests.httpErrorBody(),

        BedrockControlPlaneFlowTests.listFoundationModels(),
        BedrockControlPlaneFlowTests.getInferenceProfile(),
    ] + (
        live
            ? BedrockControlPlaneLiveFlowTests.flows
                + BedrockRuntimeLiveFlowTests.flows
            : []
    )
}
