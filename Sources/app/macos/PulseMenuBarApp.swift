import AppKit
import Combine
import FeatureHomescreen
import FeaturePulseDomain
import FeaturePulsePresentation
import SwiftUI
import os

@main
struct PulseMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

private let log = Logger(subsystem: "com.pulse5ctl", category: "app")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        for window in NSApplication.shared.windows {
            window.isRestorable = false
            window.close()
        }

        let dependencies = AppGraph.shared.appDependencies
        dependencies.pulseFeature.send(.lifecycle(.started))
        statusBarController = StatusBarController(dependencies: dependencies)

        let feature = dependencies.pulseFeature
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                log.notice("System wake notification received")
                feature.send(.lifecycle(.systemDidWake))
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
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
            .map(\.connectionState)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] connectionState in
                self?.updateIcon(for: connectionState)
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
