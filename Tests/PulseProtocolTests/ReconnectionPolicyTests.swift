@testable import FeaturePulseData
import FeaturePulseDomain
import XCTest

final class ReconnectionPolicyTests: XCTestCase {

    // MARK: - nextAttempt

    func test_nextAttempt_firstAttempt_returnsReconnectWithBaseDelay() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.nextAttempt(hasPeripheral: true)

        XCTAssertEqual(decision, .reconnect(delay: 1_000_000_000, attempt: 1))
        XCTAssertEqual(policy.attempt, 1)
    }

    func test_nextAttempt_secondAttempt_returnsDoubledDelay() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)

        let decision = policy.nextAttempt(hasPeripheral: true)

        XCTAssertEqual(decision, .reconnect(delay: 2_000_000_000, attempt: 2))
    }

    func test_nextAttempt_thirdAttempt_returns4xDelay() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)
        _ = policy.nextAttempt(hasPeripheral: true)

        let decision = policy.nextAttempt(hasPeripheral: true)

        XCTAssertEqual(decision, .reconnect(delay: 4_000_000_000, attempt: 3))
    }

    func test_nextAttempt_afterMaxAttempts_returnsGiveUp() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)
        _ = policy.nextAttempt(hasPeripheral: true)
        _ = policy.nextAttempt(hasPeripheral: true)

        let decision = policy.nextAttempt(hasPeripheral: true)

        XCTAssertEqual(decision, .giveUp)
    }

    func test_nextAttempt_shouldReconnectFalse_returnsSkip() {
        var policy = ReconnectionPolicy()

        let decision = policy.nextAttempt(hasPeripheral: true)

        XCTAssertEqual(decision, .skip)
    }

    func test_nextAttempt_noPeripheral_returnsSkip() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.nextAttempt(hasPeripheral: false)

        XCTAssertEqual(decision, .skip)
    }

    // MARK: - State transitions

    func test_connectionSucceeded_resetsAttemptCounter() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)
        _ = policy.nextAttempt(hasPeripheral: true)

        policy.connectionSucceeded()

        XCTAssertEqual(policy.attempt, 0)
        XCTAssertTrue(policy.shouldReconnect)
    }

    func test_userDisconnected_clearsShouldReconnectAndAttempt() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)

        policy.userDisconnected()

        XCTAssertFalse(policy.shouldReconnect)
        XCTAssertEqual(policy.attempt, 0)
    }

    // MARK: - timeoutAction

    func test_timeoutAction_reconnectingState_cancelConnection() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.timeoutAction(hasPeripheral: true, state: .reconnecting(attempt: 1))

        XCTAssertEqual(decision, .cancelConnection)
    }

    func test_timeoutAction_connectingState_cancelConnection() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.timeoutAction(hasPeripheral: true, state: .connecting)

        XCTAssertEqual(decision, .cancelConnection)
    }

    func test_timeoutAction_connectedState_ignore() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.timeoutAction(hasPeripheral: true, state: .connected)

        XCTAssertEqual(decision, .ignore)
    }

    func test_timeoutAction_noPeripheral_reconnectDirectly() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()

        let decision = policy.timeoutAction(hasPeripheral: false, state: .connecting)

        XCTAssertEqual(decision, .reconnectDirectly)
    }

    // MARK: - reset

    func test_reset_clearsAllState() {
        var policy = ReconnectionPolicy()
        policy.connectionStarted()
        _ = policy.nextAttempt(hasPeripheral: true)
        _ = policy.nextAttempt(hasPeripheral: true)

        policy.reset()

        XCTAssertFalse(policy.shouldReconnect)
        XCTAssertEqual(policy.attempt, 0)
    }
}
