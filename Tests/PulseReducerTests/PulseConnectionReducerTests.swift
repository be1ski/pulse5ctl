@testable import CoreElm
import FeaturePulseDomain
@testable import FeaturePulsePresentation
import Foundation
import XCTest

final class PulseConnectionReducerTests: XCTestCase {

    // MARK: - Helpers

    private func reduce(
        _ action: PulseAction.Connection,
        state: PulseState = PulseState()
    ) -> ReducerResult<PulseState, PulseEffect, Never> {
        let context = ReducerContext<PulseState, PulseEffect, Never>()
        pulseConnectionReducer(action, state, context)
        return context.result(initialState: state)
    }

    // MARK: - Connect Tapped

    func test_connectTapped_setsStateToScanning() {
        let result = reduce(.connectTapped)
        XCTAssertEqual(result.state.connectionState, .scanning)
    }

    func test_connectTapped_clearsError() {
        let state = PulseState(errorMessage: "Some error")
        let result = reduce(.connectTapped, state: state)
        XCTAssertNil(result.state.errorMessage)
    }

    func test_connectTapped_emitsStartScan() {
        let result = reduce(.connectTapped)
        XCTAssertEqual(result.effects.commands, [.startScan])
    }

    // MARK: - Disconnect Tapped

    func test_disconnectTapped_setsStateToDisconnected() {
        let state = PulseState(connectionState: .connected)
        let result = reduce(.disconnectTapped, state: state)
        XCTAssertEqual(result.state.connectionState, .disconnected)
    }

    func test_disconnectTapped_clearsDeviceName() {
        let state = PulseState(connectedDeviceName: "Pulse 5")
        let result = reduce(.disconnectTapped, state: state)
        XCTAssertNil(result.state.connectedDeviceName)
    }

    func test_disconnectTapped_clearsDiscoveredDevices() {
        let device = DiscoveredDevice(id: UUID(), name: "Pulse 5", rssi: -50, hasPulseService: true)
        let state = PulseState(discoveredDevices: [device])
        let result = reduce(.disconnectTapped, state: state)
        XCTAssertTrue(result.state.discoveredDevices.isEmpty)
    }

    func test_disconnectTapped_emitsDisconnect() {
        let result = reduce(.disconnectTapped)
        XCTAssertEqual(result.effects.commands, [.disconnect])
    }

    // MARK: - Select Device

    func test_selectDevice_setsStateToConnecting() {
        let id = UUID()
        let device = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -50, hasPulseService: true)
        let state = PulseState(discoveredDevices: [device])
        let result = reduce(.selectDevice(id), state: state)
        XCTAssertEqual(result.state.connectionState, .connecting)
    }

    func test_selectDevice_setsDeviceName() {
        let id = UUID()
        let device = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -50, hasPulseService: true)
        let state = PulseState(discoveredDevices: [device])
        let result = reduce(.selectDevice(id), state: state)
        XCTAssertEqual(result.state.connectedDeviceName, "Pulse 5")
    }

    func test_selectDevice_clearsError() {
        let id = UUID()
        let device = DiscoveredDevice(id: id, name: "Pulse 5", rssi: -50, hasPulseService: true)
        let state = PulseState(discoveredDevices: [device], errorMessage: "Old error")
        let result = reduce(.selectDevice(id), state: state)
        XCTAssertNil(result.state.errorMessage)
    }

    func test_selectDevice_emitsConnect() {
        let id = UUID()
        let result = reduce(.selectDevice(id))
        XCTAssertEqual(result.effects.commands, [.connect(id)])
    }

    func test_selectDevice_unknownDevice_deviceNameIsNil() {
        let id = UUID()
        let result = reduce(.selectDevice(id))
        XCTAssertNil(result.state.connectedDeviceName)
    }
}
