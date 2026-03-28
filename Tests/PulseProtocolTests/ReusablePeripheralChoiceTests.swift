@testable import FeaturePulseData
import CoreBluetooth
import XCTest

final class ReusablePeripheralChoiceTests: XCTestCase {

    func test_select_prefersConnectedServicePeripheral() {
        let choice = ReusablePeripheralChoice.select(
            hasConnectedServicePeripheral: true,
            cachedPeripheralState: .connected
        )

        XCTAssertEqual(choice, .connectedService)
    }

    func test_select_returnsCached_whenCachedPeripheralIsConnected() {
        let choice = ReusablePeripheralChoice.select(
            hasConnectedServicePeripheral: false,
            cachedPeripheralState: .connected
        )

        XCTAssertEqual(choice, .cached)
    }

    func test_select_returnsCached_whenCachedPeripheralIsDisconnected() {
        let choice = ReusablePeripheralChoice.select(
            hasConnectedServicePeripheral: false,
            cachedPeripheralState: .disconnected
        )

        XCTAssertEqual(choice, .cached)
    }

    func test_select_returnsNone_whenNothingIsConnected() {
        let choice = ReusablePeripheralChoice.select(
            hasConnectedServicePeripheral: false,
            cachedPeripheralState: nil
        )

        XCTAssertEqual(choice, .none)
    }
}
