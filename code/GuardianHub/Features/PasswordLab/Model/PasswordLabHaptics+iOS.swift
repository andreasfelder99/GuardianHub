#if os(iOS)
import CoreHaptics
import Foundation

/// CoreHaptics-only (no UIKit). Subtle feedback on category changes.
final class PasswordLabHaptics {
    private var engine: CHHapticEngine?

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            try e.start()
            engine = e
        } catch {
            engine = nil
        }
    }

    func playTransition(to category: PasswordStrengthCategory) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine else { return }

        // Keep it subtle: one transient "tap".
        let intensity: Float
        let sharpness: Float

        switch category {
        case .veryWeak:
            intensity = 0.25
            sharpness = 0.35
        case .weak:
            intensity = 0.35
            sharpness = 0.45
        case .fair:
            intensity = 0.45
            sharpness = 0.55
        case .strong:
            intensity = 0.60
            sharpness = 0.70
        }

        do {
            let params = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ]

            let event = CHHapticEvent(eventType: .hapticTransient, parameters: params, relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fail silently; haptics are optional polish.
        }
    }
}
#endif
