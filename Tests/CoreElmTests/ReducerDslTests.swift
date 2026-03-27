@testable import CoreElm
import XCTest

private enum TestAction: ElmAction, Equatable {
    case increment
    case setTo(Int)
}

private enum TestCommand: Equatable {
    case save(Int)
}

final class ReducerDslTests: XCTestCase {

    func test_context_multipleStateCalls_composesTransforms() {
        let context = ReducerContext<[String: Int], Never, Never>()
        context.state { var state = $0; state["a"] = 1; return state }
        context.state { var state = $0; state["b"] = 2; return state }
        let result = context.result(initialState: [:])
        XCTAssertEqual(result.state, ["a": 1, "b": 2])
    }

    func test_context_multipleInoutStateCalls_composesTransforms() {
        let context = ReducerContext<[String: Int], Never, Never>()
        context.state { $0["a"] = 1 }
        context.state { $0["b"] = 2 }
        let result = context.result(initialState: [:])
        XCTAssertEqual(result.state, ["a": 1, "b": 2])
    }

    func test_reducer_createsWorkingReducer() {
        let testReducer: Reducer<TestAction, Int, TestCommand, Never> = reducer { action, _, context in
            switch action {
            case .increment:
                context.state { $0 + 1 }
            case let .setTo(value):
                context.state(value)
                context.command(.save(value))
            }
        }

        let result1 = testReducer(.increment, 5)
        XCTAssertEqual(result1.state, 6)
        XCTAssertTrue(result1.effects.commands.isEmpty)

        let result2 = testReducer(.setTo(42), 0)
        XCTAssertEqual(result2.state, 42)
        XCTAssertEqual(result2.effects.commands, [.save(42)])
    }
}
