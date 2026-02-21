import CoreElm
import FeaturePulseDomain

func pulseLightScheduleReducer(
    _ action: PulseAction.LightSchedule,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleEnabled:
        handleToggleEnabled(state, context)
    case let .setOffTime(hour, minute):
        handleSetTime(hour: hour, minute: minute, kind: .offTime, state: state, context: context)
    case let .setOnTime(hour, minute):
        handleSetTime(hour: hour, minute: minute, kind: .onTime, state: state, context: context)
    }
}

private enum TimeKind { case offTime, onTime }

private func handleToggleEnabled(
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let newEnabled = !state.lightScheduleSettings.enabled
    context.state {
        $0.lightScheduleSettings.enabled = newEnabled
    }
    context.command(.saveLightScheduleSettings(
        state.lightScheduleSettings.with(enabled: newEnabled)
    ))

    if newEnabled {
        context.command(.observeLightSchedule(
            state.lightScheduleSettings.with(enabled: newEnabled)
        ))
    } else {
        context.command(.stopLightSchedule)
        if state.lightScheduleActive {
            // Disabling while in off-window: restore lights
            let bodyLight = state.savedBodyLightOn ?? true
            let projection = state.savedProjectionOn ?? true
            context.state {
                $0.lightScheduleActive = false
                $0.bodyLightOn = bodyLight
                $0.projectionOn = projection
                $0.savedBodyLightOn = nil
                $0.savedProjectionOn = nil
            }
            if state.connectionState.isConnected {
                context.command(.setBrightness(
                    level: state.brightness,
                    bodyLight: bodyLight,
                    projection: projection
                ))
            }
        }
    }
}

private func handleSetTime(
    hour: Int,
    minute: Int,
    kind: TimeKind,
    state: PulseState,
    context: ReducerContext<PulseState, PulseEffect, Never>
) {
    let newSettings: LightScheduleSettings
    switch kind {
    case .offTime:
        newSettings = state.lightScheduleSettings.with(offHour: hour, offMinute: minute)
        context.state {
            $0.lightScheduleSettings.offHour = hour
            $0.lightScheduleSettings.offMinute = minute
        }
    case .onTime:
        newSettings = state.lightScheduleSettings.with(onHour: hour, onMinute: minute)
        context.state {
            $0.lightScheduleSettings.onHour = hour
            $0.lightScheduleSettings.onMinute = minute
        }
    }
    context.command(.saveLightScheduleSettings(newSettings))
    if state.lightScheduleSettings.enabled {
        context.command(.observeLightSchedule(newSettings))
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
