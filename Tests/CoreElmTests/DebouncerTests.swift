import CoreElm
import XCTest

final class DebouncerTests: XCTestCase {

    func test_run_executesAfterDelay() async throws {
        let debouncer = Debouncer()
        let expectation = XCTestExpectation(description: "operation ran")

        await debouncer.run(delay: .milliseconds(50)) {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_run_calledTwice_cancelsPreviousOperation() async throws {
        let debouncer = Debouncer()
        var firstRan = false
        let secondExpectation = XCTestExpectation(description: "second ran")

        await debouncer.run(delay: .milliseconds(100)) {
            firstRan = true
        }

        await debouncer.run(delay: .milliseconds(50)) {
            secondExpectation.fulfill()
        }

        await fulfillment(of: [secondExpectation], timeout: 1.0)
        XCTAssertFalse(firstRan, "First operation should have been cancelled")
    }

    func test_cancel_preventsExecution() async throws {
        let debouncer = Debouncer()
        var didRun = false

        await debouncer.run(delay: .milliseconds(50)) {
            didRun = true
        }

        await debouncer.cancel()

        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(didRun, "Operation should have been cancelled")
    }
}
