@testable import FeaturePulseData
import XCTest

final class BluetoothErrorTests: XCTestCase {

    func test_errorDescription_poweredOff_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.poweredOff.errorDescription)
        XCTAssertFalse(BluetoothError.poweredOff.errorDescription!.isEmpty)
    }

    func test_errorDescription_unauthorized_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.unauthorized.errorDescription)
        XCTAssertFalse(BluetoothError.unauthorized.errorDescription!.isEmpty)
    }

    func test_errorDescription_unsupported_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.unsupported.errorDescription)
        XCTAssertFalse(BluetoothError.unsupported.errorDescription!.isEmpty)
    }

    func test_errorDescription_serviceNotFound_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.serviceNotFound.errorDescription)
        XCTAssertFalse(BluetoothError.serviceNotFound.errorDescription!.isEmpty)
    }

    func test_errorDescription_characteristicNotFound_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.characteristicNotFound.errorDescription)
        XCTAssertFalse(BluetoothError.characteristicNotFound.errorDescription!.isEmpty)
    }

    func test_errorDescription_connectionFailed_isNotEmpty() {
        let error = BluetoothError.connectionFailed("timeout")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_errorDescription_writeFailed_isNotEmpty() {
        let error = BluetoothError.writeFailed("not connected")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_errorDescription_disconnected_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.disconnected.errorDescription)
        XCTAssertFalse(BluetoothError.disconnected.errorDescription!.isEmpty)
    }

    func test_errorDescription_unknownDevice_isNotEmpty() {
        XCTAssertNotNil(BluetoothError.unknownDevice.errorDescription)
        XCTAssertFalse(BluetoothError.unknownDevice.errorDescription!.isEmpty)
    }

    func test_errorDescription_allCases_areUnique() {
        let descriptions: [String?] = [
            BluetoothError.poweredOff.errorDescription,
            BluetoothError.unauthorized.errorDescription,
            BluetoothError.unsupported.errorDescription,
            BluetoothError.serviceNotFound.errorDescription,
            BluetoothError.characteristicNotFound.errorDescription,
            BluetoothError.disconnected.errorDescription,
            BluetoothError.unknownDevice.errorDescription
        ]
        let nonNil = descriptions.compactMap { $0 }
        XCTAssertEqual(nonNil.count, Set(nonNil).count, "All error descriptions should be unique")
    }
}
