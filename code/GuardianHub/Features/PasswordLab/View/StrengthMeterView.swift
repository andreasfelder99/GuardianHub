import SwiftUI

struct StrengthMeterCard: View {
    let result: PasswordAnalysisResult
    private let estimator = PasswordCrackTimeEstimator()

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Strength", systemImage: result.category.systemImage)
                        .font(.headline)

                    Spacer()

                    Text(result.category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }

                Gauge(value: result.meterValue) {
                    Text("Strength")
                } currentValueLabel: {
                    Text("\(Int(result.entropyBits.rounded())) bits")
                        .font(.subheadline.weight(.semibold))
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(tintForCategory(result.category))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Estimated entropy")
                        .font(.subheadline.weight(.semibold))
                    Text(entropyExplanationText(for: result))
                        .foregroundStyle(.secondary)
                }

                Divider()

                timeToGuessSection
            }
        } label: {
            Text("Overview")
        }
    }

    private var timeToGuessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time to guess (estimate)")
                .font(.subheadline.weight(.semibold))

            if result.passwordLength == 0 {
                Text("Enter a password to see how long different attack scenarios might take.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    scenarioRow(.online)
                    scenarioRow(.offlineModerate)

                    Text("These numbers assume an attacker searches the full space implied by the entropy estimate. Real outcomes vary by hash algorithm, rate limits, and attacker resources.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        }
    }

    private func scenarioRow(_ scenario: PasswordCrackTimeEstimator.Scenario) -> some View {
        let estimate = estimator.estimate(entropyBits: result.entropyBits, scenario: scenario)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(scenario.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(estimator.formatRange(expectedSeconds: estimate.expectedSeconds, worstSeconds: estimate.worstSeconds))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }

            if let footnote = scenario.footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tintForCategory(_ category: PasswordStrengthCategory) -> Color {
        switch category {
        case .veryWeak: return .red
        case .weak: return .orange
        case .fair: return .yellow
        case .strong: return .green
        }
    }

    private func entropyExplanationText(for result: PasswordAnalysisResult) -> String {
        if result.passwordLength == 0 {
            return "Start typing to see how length and character variety affect entropy."
        }

        if result.entropyBits < 28 {
            return "This is likely guessable quickly. Increase length and avoid common patterns."
        } else if result.entropyBits < 36 {
            return "Better, but still vulnerable to targeted guessing. Add length and unpredictability."
        } else if result.entropyBits < 60 {
            return "Reasonable strength for many uses. Consider longer passphrases for high-value accounts."
        } else {
            return "Strong. Length + variety with minimal patterns is hard to guess."
        }
    }
}
