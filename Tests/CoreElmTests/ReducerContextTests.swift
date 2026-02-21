@testable import CoreElm
import XCTest

final class ReducerContextTests: XCTestCase {

    // MARK: - State

    func test_state_withTransform_updatesState() {
        let context = ReducerContext<Int, String, String>()
        context.state { $0 + 10 }
        let result = context.result(initialState: 5)
        XCTAssertEqual(result.state, 15)
    }

    func test_state_withValue_replacesState() {
        let context = ReducerContext<Int, String, String>()
        context.state(42)
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.state, 42)
    }

    func test_result_withNoStateUpdate_returnsInitialState() {
        let context = ReducerContext<Int, String, String>()
        let result = context.result(initialState: 7)
        XCTAssertEqual(result.state, 7)
    }

    func test_state_withInoutMutation_updatesState() {
        let context = ReducerContext<(x: Int, y: String), String, String>()
        context.state {
            $0.x = 42
            $0.y = "hello"
        }
        let result = context.result(initialState: (x: 0, y: ""))
        XCTAssertEqual(result.state.x, 42)
        XCTAssertEqual(result.state.y, "hello")
    }

    func test_state_withMultipleUpdates_lastUpdateWins() {
        let context = ReducerContext<Int, String, String>()
        context.state { $0 + 1 }
        context.state { $0 * 2 }
        let result = context.result(initialState: 5)
        XCTAssertEqual(result.state, 10)
    }

    // MARK: - Commands

    func test_command_single_addsToCommands() {
        let context = ReducerContext<Int, String, String>()
        context.command("doSomething")
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.commands, ["doSomething"])
    }

    func test_commands_variadic_addsAllToCommands() {
        let context = ReducerContext<Int, String, String>()
        context.commands("a", "b", "c")
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.commands, ["a", "b", "c"])
    }

    func test_commands_array_addsAllToCommands() {
        let context = ReducerContext<Int, String, String>()
        context.commands(["x", "y"])
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.commands, ["x", "y"])
    }

    func test_command_calledMultipleTimes_accumulates() {
        let context = ReducerContext<Int, String, String>()
        context.command("first")
        context.command("second")
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.commands, ["first", "second"])
    }

    func test_result_withNoCommands_returnsEmptyArray() {
        let context = ReducerContext<Int, String, String>()
        let result = context.result(initialState: 0)
        XCTAssertTrue(result.effects.commands.isEmpty)
    }

    // MARK: - Notifications

    func test_notify_single_addsToNotifications() {
        let context = ReducerContext<Int, String, String>()
        context.notify("event")
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.notifications, ["event"])
    }

    func test_notifications_variadic_addsAllToNotifications() {
        let context = ReducerContext<Int, String, String>()
        context.notifications("a", "b")
        let result = context.result(initialState: 0)
        XCTAssertEqual(result.effects.notifications, ["a", "b"])
    }

    func test_result_withNoNotifications_returnsEmptyArray() {
        let context = ReducerContext<Int, String, String>()
        let result = context.result(initialState: 0)
        XCTAssertTrue(result.effects.notifications.isEmpty)
    }
}
