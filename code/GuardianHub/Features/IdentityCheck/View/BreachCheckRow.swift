import SwiftUI

struct BreachCheckRow: View {
    let check: BreachCheck

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: check.breachCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(check.breachCount > 0 ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(check.emailAddress)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(trailing)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if check.breachCount == 0 {
            return "No breaches stored"
        }
        return "\(check.breachCount) breach\(check.breachCount == 1 ? "" : "es") stored"
    }

    private var trailing: String {
        guard let lastCheckedAt = check.lastCheckedAt else { return "Never" }
        return lastCheckedAt.formatted(date: .abbreviated, time: .omitted)
    }
}
