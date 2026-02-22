@testable import CoreElm
import XCTest

// MARK: - Test types

private enum TestAction: ElmAction, Equatable {
    case increment
    case decrement
    case set(Int)
    case triggerCommand
    case triggerNotification
}

private enum TestCommand: Equatable, Sendable {
    case load
    case save(Int)
}

private enum TestNotification: Equatable, Sendable {
    case didUpdate(Int)
}

// MARK: - Test reducer

private func testReducer(
    action: TestAction,
    state: Int
) -> ReducerResult<Int, TestCommand, TestNotification> {
    switch action {
    case .increment:
        return ReducerResult(state: state + 1, effects: Effects())
    case .decrement:
        return ReducerResult(state: state - 1, effects: Effects())
    case let .set(value):
        return ReducerResult(state: value, effects: Effects())
    case .triggerCommand:
        return ReducerResult(state: state, effects: Effects(commands: [.load]))
    case .triggerNotification:
        return ReducerResult(state: state, effects: Effects(notifications: [.didUpdate(state)]))
    }
}

// MARK: - Test effect handler

private func testEffectHandler(command: TestCommand) -> AsyncStream<TestAction> {
    switch command {
    case .load:
        return AsyncStream { continuation in
            continuation.yield(.set(42))
            continuation.finish()
        }
    case .save:
        return AsyncStream { $0.finish() }
    }
}

// MARK: - Tests

final class FeatureImplTests: XCTestCase {

    // MARK: - Helpers

    @MainActor
    private func makeFeature(
        initialState: Int = 0,
        initialCommands: [TestCommand] = []
    ) -> Feature<TestAction, Int, TestCommand, TestNotification> {
        Feature(
            initialState: initialState,
            reducer: testReducer,
            effectHandler: testEffectHandler,
            initialCommands: initialCommands
        )
    }

    // MARK: - Init

    @MainActor
    func test_init_setsInitialState() {
        let feature = makeFeature(initialState: 7)
        XCTAssertEqual(feature.state, 7)
    }

    // MARK: - Launch

    @MainActor
    func test_launch_executesInitialCommands() async throws {
        let feature = makeFeature(initialState: 0, initialCommands: [.load])
        feature.launch()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state, 42)
    }

    @MainActor
    func test_launch_calledTwice_isIdempotent() async throws {
        nonisolated(unsafe) var loadCount = 0
        let feature = Feature<TestAction, Int, TestCommand, TestNotification>(
            initialState: 0,
            reducer: testReducer,
            effectHandler: { command in
                AsyncStream { continuation in
                    if case .load = command {
                        loadCount += 1
                        continuation.yield(.set(42))
                    }
                    continuation.finish()
                }
            },
            initialCommands: [.load]
        )

        feature.launch()
        feature.launch()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(loadCount, 1)
    }

    // MARK: - Send

    @MainActor
    func test_send_increment_updatesState() {
        let feature = makeFeature(initialState: 0)
        feature.send(.increment)
        XCTAssertEqual(feature.state, 1)
    }

    @MainActor
    func test_send_decrement_updatesState() {
        let feature = makeFeature(initialState: 0)
        feature.send(.decrement)
        XCTAssertEqual(feature.state, -1)
    }

    @MainActor
    func test_send_multipleActions_processesInOrder() {
        let feature = makeFeature(initialState: 0)
        feature.send(.increment)
        feature.send(.increment)
        feature.send(.decrement)
        XCTAssertEqual(feature.state, 1)
    }

    @MainActor
    func test_send_triggerCommand_effectFeedsBackAction() async throws {
        let feature = makeFeature(initialState: 0)
        feature.send(.triggerCommand)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(feature.state, 42)
    }

    @MainActor
    func test_send_triggerNotification_yieldsNotification() async throws {
        let feature = makeFeature(initialState: 99)
        var iterator = feature.notifications.makeAsyncIterator()

        feature.send(.triggerNotification)

        let received = await iterator.next()
        XCTAssertEqual(received, .didUpdate(99))
    }
}
