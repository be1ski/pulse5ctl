import CoreElm
import XCTest

private enum TestAction: ElmAction, Equatable {
    case one
    case two
    case three
}

final class FlowHelpersTests: XCTestCase {

    func test_action_yieldsSingleValue() async {
        let stream: AsyncStream<TestAction> = action(.one)
        var collected: [TestAction] = []
        for await value in stream {
            collected.append(value)
        }
        XCTAssertEqual(collected, [.one])
    }

    func test_actions_yieldsMultipleValues() async {
        let stream: AsyncStream<TestAction> = actions { continuation in
            continuation.yield(.one)
            continuation.yield(.two)
            continuation.yield(.three)
            continuation.finish()
        }
        var collected: [TestAction] = []
        for await value in stream {
            collected.append(value)
        }
        XCTAssertEqual(collected, [.one, .two, .three])
    }

    func test_sideEffect_runsOperationAndYieldsNothing() async {
        var didRun = false
        let stream: AsyncStream<TestAction> = sideEffect {
            didRun = true
        }
        var collected: [TestAction] = []
        for await value in stream {
            collected.append(value)
        }
        XCTAssertTrue(didRun)
        XCTAssertTrue(collected.isEmpty)
    }

    func test_noActions_yieldsNothing() async {
        let stream: AsyncStream<TestAction> = noActions()
        var collected: [TestAction] = []
        for await value in stream {
            collected.append(value)
        }
        XCTAssertTrue(collected.isEmpty)
    }
}
