import CoreElm

func pulseControlsReducer(
    _ action: PulseAction.Controls,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case .toggleLight:
        let toggled = !state.lightOn
        context.state { current in
            var updated = current
            updated.lightOn = toggled
            return updated
        }
        context.command(.setLight(toggled))

    case let .selectTheme(theme):
        context.state { current in
            var updated = current
            updated.selectedTheme = theme
            return updated
        }
        context.command(.setTheme(theme))

    case let .setBrightness(value):
        let clamped = clampBrightness(value)
        context.state { current in
            var updated = current
            updated.brightness = clamped
            return updated
        }
        context.command(.setBrightness(level: clamped, bodyLight: state.bodyLightOn, projection: state.projectionOn))

    case .toggleBodyLight:
        let toggled = !state.bodyLightOn
        context.state { current in
            var updated = current
            updated.bodyLightOn = toggled
            return updated
        }
        context.command(.setBrightness(level: state.brightness, bodyLight: toggled, projection: state.projectionOn))

    case .toggleProjection:
        let toggled = !state.projectionOn
        context.state { current in
            var updated = current
            updated.projectionOn = toggled
            return updated
        }
        context.command(.setBrightness(level: state.brightness, bodyLight: state.bodyLightOn, projection: toggled))

    case let .setSpeed(speed):
        context.state { current in
            var updated = current
            updated.speed = speed
            return updated
        }
        context.command(.setSpeed(speed))
    }
}

private func clampBrightness(_ value: Double) -> UInt8 {
    let clamped = min(max(value, 20), 80)
    return UInt8(clamped.rounded())
}
