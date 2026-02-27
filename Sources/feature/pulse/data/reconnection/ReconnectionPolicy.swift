import FeaturePulseDomain

struct ReconnectionPolicy {
    private(set) var attempt = 0
    private(set) var shouldReconnect = false

    enum Decision: Equatable {
        case reconnect(delay: UInt64, attempt: Int)
        case giveUp
        case skip
    }

    enum TimeoutDecision: Equatable {
        case cancelConnection
        case reconnectDirectly
        case ignore
    }

    mutating func connectionStarted() {
        shouldReconnect = true
    }

    mutating func userDisconnected() {
        shouldReconnect = false
        attempt = 0
    }

    mutating func connectionSucceeded() {
        attempt = 0
    }

    mutating func reset() {
        shouldReconnect = false
        attempt = 0
    }

    mutating func nextAttempt(hasPeripheral: Bool) -> Decision {
        guard shouldReconnect else { return .skip }
        guard hasPeripheral else { return .skip }
        guard attempt < PulseConstants.maxReconnectAttempts else { return .giveUp }

        attempt += 1
        let delay = delay(forAttempt: attempt)
        return .reconnect(delay: delay, attempt: attempt)
    }

    func shouldTimeout(state: ConnectionState) -> Bool {
        switch state {
        case .connecting, .scanning, .reconnecting:
            return true
        case .disconnected, .discoveringServices, .connected:
            return false
        }
    }

    func timeoutAction(hasPeripheral: Bool, state: ConnectionState) -> TimeoutDecision {
        guard shouldTimeout(state: state) else { return .ignore }
        if hasPeripheral {
            return .cancelConnection
        } else {
            return .reconnectDirectly
        }
    }

    func delay(forAttempt attempt: Int) -> UInt64 {
        PulseConstants.baseReconnectDelay * UInt64(1 << (attempt - 1))
    }
}
