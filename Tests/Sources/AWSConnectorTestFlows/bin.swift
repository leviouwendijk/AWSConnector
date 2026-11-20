import TestFlows

@main
enum AWSConnectorTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AWSConnectorTestSuite.self
        )
    }
}
