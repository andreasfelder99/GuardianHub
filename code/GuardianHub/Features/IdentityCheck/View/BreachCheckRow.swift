import SwiftUI

struct BreachCheckRow: View {
    let check: BreachCheck

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(check.emailAddress)
                .font(.headline)

            HStack(spacing: 8) {
                Text("Breaches: \(check.breachCount)")
                    .font(.subheadline)
                    .foregroundStyle(check.breachCount > 0 ? .orange : .secondary)

                if let lastCheckedAt = check.lastCheckedAt {
                    Text(lastCheckedAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Never checked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
