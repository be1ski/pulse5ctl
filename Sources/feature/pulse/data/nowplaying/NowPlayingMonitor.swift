import CoreAudio
import FeaturePulseDomain
import Foundation

public final class NowPlayingMonitor {
    private let center = DistributedNotificationCenter.default()

    public init() {}

    public func observe() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            var spotifyPlaying = false
            var musicPlaying = false

            func update() {
                let isPlaying = spotifyPlaying || musicPlaying
                let throughPulse = isPlaying && Self.isDefaultOutputPulse()
                continuation.yield(throughPulse)
            }

            let spotifyObserver = center.addObserver(
                forName: Notification.Name("com.spotify.client.PlaybackStateChanged"),
                object: nil,
                queue: .main
            ) { notification in
                let state = notification.userInfo?["Player State"] as? String
                spotifyPlaying = (state == "Playing")
                update()
            }

            let musicObserver = center.addObserver(
                forName: Notification.Name("com.apple.Music.playerInfo"),
                object: nil,
                queue: .main
            ) { notification in
                let state = notification.userInfo?["Player State"] as? String
                musicPlaying = (state == "Playing")
                update()
            }

            let removeAudioListener = Self.addOutputDeviceListener { update() }

            continuation.onTermination = { [center] _ in
                center.removeObserver(spotifyObserver)
                center.removeObserver(musicObserver)
                removeAudioListener()
            }
        }
    }

    private static func addOutputDeviceListener(
        onDeviceChange: @escaping () -> Void
    ) -> (() -> Void) {
        var audioAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let audioBlock: AudioObjectPropertyListenerBlock = { _, _ in
            onDeviceChange()
        }
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &audioAddress,
            DispatchQueue.main,
            audioBlock
        )
        return {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &addr,
                DispatchQueue.main,
                audioBlock
            )
        }
    }

    private static func isDefaultOutputPulse() -> Bool {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        ) == noErr else {
            return false
        }

        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var nameSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceID, &nameAddress, 0, nil, &nameSize
        ) == noErr else {
            return false
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(nameSize))
        defer { buffer.deallocate() }

        guard AudioObjectGetPropertyData(
            deviceID, &nameAddress, 0, nil, &nameSize, buffer
        ) == noErr else {
            return false
        }

        let deviceName = buffer.withMemoryRebound(to: CFString.self, capacity: 1) { $0.pointee } as String
        return deviceName.localizedCaseInsensitiveContains("JBL Pulse")
    }
}
