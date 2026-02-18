import CoreElm
import CoreLocalization

func pulseSettingsReducer(
    _ action: PulseAction.Settings,
    _ state: PulseState,
    _ context: ReducerContext<PulseState, PulseEffect, Never>
) {
    switch action {
    case let .setLanguage(locale):
        L10n.overrideLocale = locale
        context.state { current in
            var updated = current
            updated.selectedLanguage = locale
            return updated
        }
        context.command(.saveLanguage(locale))
    }
}
