import SwiftUI
import SwiftData

struct IdentityCheckSummaryTile: View {
    // get all checks sorted by most recently checked
    @Query(sort: \BreachCheck.lastCheckedAt, order: .reverse) private var checks: [BreachCheck]

    // callback when user taps to open identity check section
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Identity Check", systemImage: "person.text.rectangle")
                    .font(.headline)

                Spacer()

                // button to navigate to identity check view
                Button(action: onOpen) {
                    Label("Open", systemImage: "arrow.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // show quick stats
            HStack(spacing: 16) {
                metric(title: "Tracked", value: "\(totalCount)", systemImage: "tray.full")
                metric(title: "At Risk", value: "\(atRiskCount)", systemImage: "exclamationmark.triangle.fill")
                metric(title: "Last Check", value: lastCheckedText, systemImage: "clock")
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // subtle border
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }

    private var totalCount: Int {
        checks.count
    }

    // count how many have breaches found
    private var atRiskCount: Int {
        checks.filter { $0.breachCount > 0 }.count
    }

    // get the most recent check date across all checks
    private var lastCheckedText: String {
        guard let date = checks.compactMap(\.lastCheckedAt).sorted(by: >).first else {
            return "Never"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    // helper to build a metric display (title + value + icon)
    private func metric(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
