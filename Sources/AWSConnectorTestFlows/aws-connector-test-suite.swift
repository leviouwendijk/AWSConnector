import TestFlows

private let live = true

struct AWSConnectorTestSuite: TestFlowRegistry {
    static let title = "AWSConnector flow tests"

    static let flows: [TestFlow] = [
        BedrockRuntimeFlowTests.bufferedResponseAndPath(),
        BedrockRuntimeFlowTests.requestSigningAndPath(),
        BedrockRuntimeFlowTests.streamTextAndMetadata(),
        BedrockRuntimeFlowTests.streamToolUse(),
        BedrockRuntimeFlowTests.serviceErrorEvent(),
        BedrockRuntimeFlowTests.httpErrorBody(),

        BedrockControlPlaneFlowTests.listFoundationModels(),
        BedrockControlPlaneFlowTests.getInferenceProfile(),

        AgentCoreGatewayFlowTests.webSearchToolCall(),
    ] + (
        live
            ? BedrockControlPlaneLiveFlowTests.flows
                + BedrockRuntimeLiveFlowTests.flows
            : []
    )
}
