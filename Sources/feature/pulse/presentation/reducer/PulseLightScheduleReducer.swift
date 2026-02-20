import CoreElm
import FeaturePulseDomain

func pulseLightScheduleReducer(
    _ action: PulseAction.LightSchedule,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleEnabled:
        let newEnabled = !state.lightScheduleSettings.enabled
        context.state { current in
            var updated = current
            updated.lightScheduleSettings.enabled = newEnabled
            return updated
        }
        context.command(.saveLightScheduleSettings(
            state.lightScheduleSettings.with(enabled: newEnabled)
        ))

        if newEnabled {
            context.command(.observeLightSchedule(
                state.lightScheduleSettings.with(enabled: newEnabled)
            ))
        } else if state.lightScheduleActive {
            // Disabling while in off-window: restore lights
            let bodyLight = state.savedBodyLightOn ?? true
            let projection = state.savedProjectionOn ?? true
            context.state { current in
                var updated = current
                updated.lightScheduleActive = false
                updated.bodyLightOn = bodyLight
                updated.projectionOn = projection
                updated.savedBodyLightOn = nil
                updated.savedProjectionOn = nil
                return updated
            }
            if state.connectionState.isConnected {
                context.command(.setBrightness(
                    level: state.brightness,
                    bodyLight: bodyLight,
                    projection: projection
                ))
            }
        }

    case let .setOffTime(hour, minute):
        let newSettings = state.lightScheduleSettings.with(offHour: hour, offMinute: minute)
        context.state { current in
            var updated = current
            updated.lightScheduleSettings.offHour = hour
            updated.lightScheduleSettings.offMinute = minute
            return updated
        }
        context.command(.saveLightScheduleSettings(newSettings))
        if state.lightScheduleSettings.enabled {
            context.command(.observeLightSchedule(newSettings))
        }

    case let .setOnTime(hour, minute):
        let newSettings = state.lightScheduleSettings.with(onHour: hour, onMinute: minute)
        context.state { current in
            var updated = current
            updated.lightScheduleSettings.onHour = hour
            updated.lightScheduleSettings.onMinute = minute
            return updated
        }
        context.command(.saveLightScheduleSettings(newSettings))
        if state.lightScheduleSettings.enabled {
            context.command(.observeLightSchedule(newSettings))
        }
    }
}

private extension LightScheduleSettings {
    func with(
        enabled: Bool? = nil,
        offHour: Int? = nil,
        offMinute: Int? = nil,
        onHour: Int? = nil,
        onMinute: Int? = nil
    ) -> LightScheduleSettings {
        LightScheduleSettings(
            enabled: enabled ?? self.enabled,
            offHour: offHour ?? self.offHour,
            offMinute: offMinute ?? self.offMinute,
            onHour: onHour ?? self.onHour,
            onMinute: onMinute ?? self.onMinute
        )
    }
}
