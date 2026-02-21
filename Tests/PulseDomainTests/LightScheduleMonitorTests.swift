@testable import FeaturePulseData
import FeaturePulseDomain
import Foundation
import XCTest

final class LightScheduleMonitorTests: XCTestCase {

    // MARK: - isInOffWindow: Same-day range (e.g. 02:00 - 10:00)

    func test_isInOffWindow_sameDayRange_insideWindow_returnsTrue() {
        let now = date(hour: 5, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_sameDayRange_beforeWindow_returnsFalse() {
        let now = date(hour: 1, minute: 30)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertFalse(result)
    }

    func test_isInOffWindow_sameDayRange_afterWindow_returnsFalse() {
        let now = date(hour: 12, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertFalse(result)
    }

    func test_isInOffWindow_sameDayRange_exactlyAtOffTime_returnsTrue() {
        let now = date(hour: 2, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_sameDayRange_exactlyAtOnTime_returnsFalse() {
        let now = date(hour: 10, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertFalse(result)
    }

    // MARK: - isInOffWindow: Cross-midnight range (e.g. 22:00 - 06:00)

    func test_isInOffWindow_crossMidnight_lateNight_returnsTrue() {
        let now = date(hour: 23, minute: 30)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_crossMidnight_earlyMorning_returnsTrue() {
        let now = date(hour: 3, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_crossMidnight_outsideWindow_returnsFalse() {
        let now = date(hour: 12, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertFalse(result)
    }

    // MARK: - isInOffWindow: Same off and on time

    func test_isInOffWindow_sameOffAndOnTime_returnsFalse() {
        let now = date(hour: 5, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 10, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertFalse(result)
    }

    // MARK: - nextTransitionDate

    func test_nextTransitionDate_whenOff_returnsOnTime() {
        let now = date(hour: 3, minute: 0)
        let next = LightScheduleMonitor.nextTransitionDate(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0),
            currentlyOff: true
        )
        // When off, next transition is the on-time
        let components = Calendar.current.dateComponents([.hour, .minute], from: next)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(next > now)
    }

    func test_nextTransitionDate_whenOn_returnsOffTime() {
        let now = date(hour: 12, minute: 0)
        let next = LightScheduleMonitor.nextTransitionDate(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0),
            currentlyOff: false
        )
        // When on, next transition is the off-time
        let components = Calendar.current.dateComponents([.hour, .minute], from: next)
        XCTAssertEqual(components.hour, 2)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(next > now)
    }

    // MARK: - Helpers

    private func date(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
