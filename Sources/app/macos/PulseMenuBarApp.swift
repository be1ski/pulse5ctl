import AppKit
import Combine
import FeatureHomescreen
import FeaturePulseDomain
import FeaturePulsePresentation
import SwiftUI

@main
struct PulseMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dependencies = AppGraph.shared.appDependencies
        dependencies.pulseFeature.send(.lifecycle(.started))
        statusBarController = StatusBarController(dependencies: dependencies)
    }
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let dependencies: AppDependencies
    private var stateCancellable: AnyCancellable?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        super.init()

        configurePopover()
        configureStatusItem()
        observeFeatureState()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 640)
        let hostingController = NSHostingController(
            rootView: AppRoot(dependencies)
        )
        popover.contentViewController = hostingController
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateIcon(for: dependencies.pulseFeature.state.connectionState)
    }

    private func observeFeatureState() {
        stateCancellable = dependencies.pulseFeature.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state.connectionState)
            }
    }

    private func updateIcon(for state: ConnectionState) {
        let symbolName: String

        switch state {
        case .connected, .scanning, .connecting, .discoveringServices, .reconnecting:
            symbolName = "hifispeaker.fill"
        case .disconnected:
            symbolName = "hifispeaker"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "pulse5ctl")?
            .withSymbolConfiguration(config) else {
            statusItem.button?.title = "P5"
            return
        }

        image.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.title = ""
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        forceActiveAppearance()
    }

    private func forceActiveAppearance() {
        guard let window = popover.contentViewController?.view.window,
              let frameView = window.contentView?.superview else { return }
        setActiveState(in: frameView)
    }

    private func setActiveState(in view: NSView) {
        if let vev = view as? NSVisualEffectView {
            vev.state = .active
        }
        for subview in view.subviews {
            setActiveState(in: subview)
        }
    }
}
