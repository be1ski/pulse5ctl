import FeaturePulseDomain
import Foundation

public final class LightScheduleMonitor: Sendable {
    public init() {}

    public func observe(settings: LightScheduleSettings) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let task = Task {
                let offComponents = DateComponents(hour: settings.offHour, minute: settings.offMinute)
                let onComponents = DateComponents(hour: settings.onHour, minute: settings.onMinute)

                while !Task.isCancelled {
                    let now = Date()
                    let calendar = Calendar.current
                    let inOffWindow = Self.isInOffWindow(
                        now: now,
                        calendar: calendar,
                        offComponents: offComponents,
                        onComponents: onComponents
                    )
                    continuation.yield(inOffWindow)

                    let nextTransition = Self.nextTransitionDate(
                        now: now,
                        calendar: calendar,
                        offComponents: offComponents,
                        onComponents: onComponents,
                        currentlyOff: inOffWindow
                    )

                    let sleepDuration = nextTransition.timeIntervalSince(now)
                    guard sleepDuration > 0 else { continue }

                    try? await Task.sleep(nanoseconds: UInt64(sleepDuration * 1_000_000_000))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    static func isInOffWindow(
        now: Date,
        calendar: Calendar,
        offComponents: DateComponents,
        onComponents: DateComponents
    ) -> Bool {
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTime = currentHour * 60 + currentMinute

        let offTime = (offComponents.hour ?? 0) * 60 + (offComponents.minute ?? 0)
        let onTime = (onComponents.hour ?? 0) * 60 + (onComponents.minute ?? 0)

        if offTime < onTime {
            // Same-day range: e.g. 02:00 - 10:00
            return currentTime >= offTime && currentTime < onTime
        } else if offTime > onTime {
            // Cross-midnight range: e.g. 22:00 - 06:00
            return currentTime >= offTime || currentTime < onTime
        } else {
            return false
        }
    }

    static func nextTransitionDate(
        now: Date,
        calendar: Calendar,
        offComponents: DateComponents,
        onComponents: DateComponents,
        currentlyOff: Bool
    ) -> Date {
        // If currently in off-window, next transition is the on-time
        // If currently in on-window, next transition is the off-time
        let targetComponents = currentlyOff ? onComponents : offComponents

        guard let next = calendar.nextDate(
            after: now,
            matching: targetComponents,
            matchingPolicy: .nextTime
        ) else {
            // Fallback: check again in 60 seconds
            return now.addingTimeInterval(60)
        }
        return next
    }
}
