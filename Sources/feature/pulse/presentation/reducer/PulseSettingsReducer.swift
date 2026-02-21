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
        context.state {
            $0.selectedLanguage = locale
        }
        context.command(.saveLanguage(locale))
    }
}
