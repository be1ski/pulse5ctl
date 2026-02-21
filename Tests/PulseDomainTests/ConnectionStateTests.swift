import FeaturePulseDomain
import XCTest

final class ConnectionStateTests: XCTestCase {

    // MARK: - isConnected

    func test_isConnected_connected_returnsTrue() {
        XCTAssertTrue(ConnectionState.connected.isConnected)
    }

    func test_isConnected_disconnected_returnsFalse() {
        XCTAssertFalse(ConnectionState.disconnected.isConnected)
    }

    func test_isConnected_scanning_returnsFalse() {
        XCTAssertFalse(ConnectionState.scanning.isConnected)
    }

    func test_isConnected_connecting_returnsFalse() {
        XCTAssertFalse(ConnectionState.connecting.isConnected)
    }

    func test_isConnected_discoveringServices_returnsFalse() {
        XCTAssertFalse(ConnectionState.discoveringServices.isConnected)
    }

    func test_isConnected_reconnecting_returnsFalse() {
        XCTAssertFalse(ConnectionState.reconnecting(attempt: 1).isConnected)
    }

    // MARK: - isActive

    func test_isActive_scanning_returnsTrue() {
        XCTAssertTrue(ConnectionState.scanning.isActive)
    }

    func test_isActive_connecting_returnsTrue() {
        XCTAssertTrue(ConnectionState.connecting.isActive)
    }

    func test_isActive_discoveringServices_returnsTrue() {
        XCTAssertTrue(ConnectionState.discoveringServices.isActive)
    }

    func test_isActive_reconnecting_returnsTrue() {
        XCTAssertTrue(ConnectionState.reconnecting(attempt: 2).isActive)
    }

    func test_isActive_disconnected_returnsFalse() {
        XCTAssertFalse(ConnectionState.disconnected.isActive)
    }

    func test_isActive_connected_returnsFalse() {
        XCTAssertFalse(ConnectionState.connected.isActive)
    }

    // MARK: - Equality

    func test_equality_reconnectingSameAttempt_isEqual() {
        XCTAssertEqual(
            ConnectionState.reconnecting(attempt: 1),
            ConnectionState.reconnecting(attempt: 1)
        )
    }

    func test_equality_reconnectingDifferentAttempt_isNotEqual() {
        XCTAssertNotEqual(
            ConnectionState.reconnecting(attempt: 1),
            ConnectionState.reconnecting(attempt: 2)
        )
    }
}
