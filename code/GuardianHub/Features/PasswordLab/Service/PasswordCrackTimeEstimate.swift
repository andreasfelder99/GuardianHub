import Foundation

struct PasswordCrackTimeEstimator: Sendable {

    struct Scenario: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        let guessesPerSecond: Double
        let footnote: String?

        static let online = Scenario(
            id: "online",
            title: "Online (rate-limited)",
            guessesPerSecond: 100,
            footnote: "Assumes throttling/lockouts. Real sites vary. 100 guesses per second."
        )

        static let offlineModerate = Scenario(
            id: "offlineModerate",
            title: "Offline (moderately powerful)",
            guessesPerSecond: 1_000_000_000,
            footnote: "Assumes fast hashing. Slow hashes (bcrypt/scrypt/Argon2) take much longer. 1 billion guesses per second."
        )
    }

    struct Estimate: Hashable, Sendable {
        /// Expected time (average case): 0.5 × 2^bits / rate
        let expectedSeconds: Double
        /// Worst-case time: 1.0 × 2^bits / rate
        let worstSeconds: Double
    }

    func estimate(entropyBits: Double, scenario: Scenario) -> Estimate {
        guard entropyBits > 0 else {
            return Estimate(expectedSeconds: 0, worstSeconds: 0)
        }

        // Use pow(2, bits). For typical UI ranges this is fine.
        let space = pow(2.0, entropyBits)

        let expected = 0.5 * space / scenario.guessesPerSecond
        let worst = 1.0 * space / scenario.guessesPerSecond

        return Estimate(expectedSeconds: expected, worstSeconds: worst)
    }

    func format(seconds: Double) -> String {
        guard seconds.isFinite else { return "Effectively never" }
        if seconds <= 1 { return "Instant" }

        // Human-ish buckets (clean for UI)
        let minute = 60.0
        let hour = 60.0 * minute
        let day = 24.0 * hour
        let year = 365.0 * day

        switch seconds {
        case ..<minute:
            return "\(Int(seconds.rounded()))s"
        case ..<hour:
            return "\(Int((seconds / minute).rounded()))m"
        case ..<day:
            return "\(Int((seconds / hour).rounded()))h"
        case ..<year:
            let days = seconds / day
            if days < 45 {
                return "\(Int(days.rounded()))d"
            } else {
                let months = days / 30
                return "\(Int(months.rounded()))mo"
            }
        default:
            let years = seconds / year
            if years < 10_000 {
                return "\(prettyInt(years))y"
            } else {
                return ">\(prettyInt(10_000))y"
            }
        }
    }

    func formatRange(expectedSeconds: Double, worstSeconds: Double) -> String {
        let e = format(seconds: expectedSeconds)
        let w = format(seconds: worstSeconds)

        if e == w { return e }
        return "\(e) avg & \(w) worst"
    }

    private func prettyInt(_ value: Double) -> String {
        let n = Int(value.rounded())
        // Simple grouping for readability
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
