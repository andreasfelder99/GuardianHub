import SwiftUI

struct BreachCheckRow: View {
    let check: BreachCheck
    
    private var statusGradient: LinearGradient {
        check.breachCount > 0 ? GuardianTheme.StatusGradient.warning.gradient : GuardianTheme.StatusGradient.success.gradient
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(statusGradient.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: check.breachCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(check.emailAddress)
                    .font(.body.weight(.semibold))

                HStack(spacing: 6) {
                    if check.breachCount > 0 {
                        Text("\(check.breachCount)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(GuardianTheme.StatusGradient.warning.gradient)
                            }
                        Text("breach\(check.breachCount == 1 ? "" : "es")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No breaches")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // last checked date on the right
            VStack(alignment: .trailing, spacing: 2) {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if check.lastCheckedAt != nil {
                    Text("checked")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var trailing: String {
        guard let lastCheckedAt = check.lastCheckedAt else { return "Never" }
        return lastCheckedAt.formatted(date: .abbreviated, time: .omitted)
    }
}
