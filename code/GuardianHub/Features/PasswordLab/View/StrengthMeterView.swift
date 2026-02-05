import SwiftUI

struct StrengthMeterCard: View {
    let result: PasswordAnalysisResult
    private let estimator = PasswordCrackTimeEstimator()
    
    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with category badge
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Image(systemName: result.category.systemImage)
                        .font(.headline)
                        .foregroundStyle(GuardianTheme.strengthGradient(for: result.category))
                    
                    Text("Strength")
                        .font(.headline)
                }

                Spacer()

                // Animated category badge
                Text(result.category.rawValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(GuardianTheme.strengthGradient(for: result.category))
                            .shadow(color: GuardianTheme.strengthColor(for: result.category).opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: result.category)
            }
            
            // Animated strength bar
            VStack(alignment: .leading, spacing: 8) {
                AnimatedGradientBar(
                    progress: result.meterValue,
                    gradient: GuardianTheme.strengthGradient(for: result.category),
                    height: 12,
                    cornerRadius: 6
                )
                
                HStack {
                    Text("\(Int(result.entropyBits.rounded())) bits")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(GuardianTheme.strengthGradient(for: result.category))
                    
                    Spacer()
                    
                    Text("of entropy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Explanation
            VStack(alignment: .leading, spacing: 6) {
                Text("Estimated entropy")
                    .font(.subheadline.weight(.semibold))
                Text(entropyExplanationText(for: result))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .overlay(GuardianTheme.strengthGradient(for: result.category).opacity(0.3))

            timeToGuessSection
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                
                // Subtle category-colored gradient
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(GuardianTheme.strengthGradient(for: result.category).opacity(0.06))
            }
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(GuardianTheme.strengthGradient(for: result.category).opacity(0.2), lineWidth: 1)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: result.category)
    }

    private var timeToGuessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.questionmark")
                    .foregroundStyle(GuardianTheme.SectionColor.passwordLab.gradient)
                Text("Time to guess (estimate)")
                    .font(.subheadline.weight(.semibold))
            }

            if result.passwordLength == 0 {
                Text("Enter a password to see how long different attack scenarios might take.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    scenarioRow(.online)
                    scenarioRow(.offlineModerate)

                    Text("These numbers assume an attacker searches the full space implied by the entropy estimate. Real outcomes vary by hash algorithm, rate limits, and attacker resources.")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func scenarioRow(_ scenario: PasswordCrackTimeEstimator.Scenario) -> some View {
        let estimate = estimator.estimate(entropyBits: result.entropyBits, scenario: scenario)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: scenario == .online ? "network" : "desktopcomputer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(scenario.title)
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
                Text(estimator.formatRange(expectedSeconds: estimate.expectedSeconds, worstSeconds: estimate.worstSeconds))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(GuardianTheme.strengthGradient(for: result.category))
            }

            if let footnote = scenario.footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.secondary.opacity(0.06))
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
