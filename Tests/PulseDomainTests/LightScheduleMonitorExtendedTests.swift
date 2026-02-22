@testable import FeaturePulseData
import FeaturePulseDomain
import Foundation
import XCTest

final class LightScheduleMonitorExtendedTests: XCTestCase {

    // MARK: - isInOffWindow edge cases

    func test_isInOffWindow_nilHourComponent_treatsAsZero() {
        let now = date(hour: 0, minute: 45)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: nil, minute: 30),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_nilMinuteComponent_treatsAsZero() {
        let now = date(hour: 2, minute: 30)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: nil),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_crossMidnight_exactlyAtOffTime_returnsTrue() {
        let now = date(hour: 22, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_crossMidnight_exactlyAtOnTime_returnsFalse() {
        let now = date(hour: 6, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertFalse(result)
    }

    func test_isInOffWindow_crossMidnight_midnight_returnsTrue() {
        let now = date(hour: 0, minute: 0)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0)
        )
        XCTAssertTrue(result)
    }

    func test_isInOffWindow_sameDayRange_oneMinuteBeforeOn_returnsTrue() {
        let now = date(hour: 9, minute: 59)
        let result = LightScheduleMonitor.isInOffWindow(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0)
        )
        XCTAssertTrue(result)
    }

    // MARK: - nextTransitionDate edge cases

    func test_nextTransitionDate_crossMidnight_whenOff_returnsOnTime() {
        let now = date(hour: 23, minute: 0)
        let next = LightScheduleMonitor.nextTransitionDate(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0),
            currentlyOff: true
        )
        let components = Calendar.current.dateComponents([.hour, .minute], from: next)
        XCTAssertEqual(components.hour, 6)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(next > now)
    }

    func test_nextTransitionDate_crossMidnight_whenOn_returnsOffTime() {
        let now = date(hour: 12, minute: 0)
        let next = LightScheduleMonitor.nextTransitionDate(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 22, minute: 0),
            onComponents: DateComponents(hour: 6, minute: 0),
            currentlyOff: false
        )
        let components = Calendar.current.dateComponents([.hour, .minute], from: next)
        XCTAssertEqual(components.hour, 22)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(next > now)
    }

    func test_nextTransitionDate_returnsDateAfterNow() {
        let now = date(hour: 5, minute: 0)
        let next = LightScheduleMonitor.nextTransitionDate(
            now: now, calendar: .current,
            offComponents: DateComponents(hour: 2, minute: 0),
            onComponents: DateComponents(hour: 10, minute: 0),
            currentlyOff: true
        )
        XCTAssertTrue(next > now)
    }

    // MARK: - observe stream

    func test_observe_yieldsFirstValue() async {
        let monitor = LightScheduleMonitor()
        let settings = LightScheduleSettings(enabled: true, offHour: 2, offMinute: 0, onHour: 10, onMinute: 0)
        let stream = monitor.observe(settings: settings)
        var iterator = stream.makeAsyncIterator()
        let value = await iterator.next()
        XCTAssertNotNil(value)
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
