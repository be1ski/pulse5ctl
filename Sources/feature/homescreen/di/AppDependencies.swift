import FeaturePulsePresentation

public struct AppDependencies {
    public let pulseFeature: PulseFeature

    public init(pulseFeature: PulseFeature) {
        self.pulseFeature = pulseFeature
    }
}
