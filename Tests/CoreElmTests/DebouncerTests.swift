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
        let firstShouldNotRun = XCTestExpectation(description: "first should not run")
        firstShouldNotRun.isInverted = true
        let secondExpectation = XCTestExpectation(description: "second ran")

        await debouncer.run(delay: .milliseconds(100)) {
            firstShouldNotRun.fulfill()
        }

        await debouncer.run(delay: .milliseconds(50)) {
            secondExpectation.fulfill()
        }

        await fulfillment(of: [secondExpectation, firstShouldNotRun], timeout: 1.0)
    }

    func test_cancel_preventsExecution() async throws {
        let debouncer = Debouncer()
        let shouldNotRun = XCTestExpectation(description: "should not run")
        shouldNotRun.isInverted = true

        await debouncer.run(delay: .milliseconds(50)) {
            shouldNotRun.fulfill()
        }

        await debouncer.cancel()

        await fulfillment(of: [shouldNotRun], timeout: 0.2)
    }
}
