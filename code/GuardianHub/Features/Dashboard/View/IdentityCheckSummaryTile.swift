import SwiftUI
import SwiftData

struct IdentityCheckSummaryTile: View {
    // get all checks, newest first
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

    // callback when user wants to open identity check section
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            // grid layout for the 3 metrics
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Tracked", value: "\(totalCount)")
                metric(title: "At Risk", value: "\(atRiskCount)")
                metric(title: "Last Check", value: lastCheckedText)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        // subtle border
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Identity Check", systemImage: "person.text.rectangle")
                    .font(.headline)

                // show status message based on current state
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // button to navigate to full identity check view
            Button(action: onOpen) {
                Label("Open", systemImage: "arrow.right")
            }
            .buttonStyle(.bordered)
        }
    }

    // grid columns for the 3 metrics. Flexible so they adapt to screen size
    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.flexible(minimum: 90), alignment: .leading)
        ]
    }

    private var totalCount: Int {
        checks.count
    }

    // count how many checks have breaches
    private var atRiskCount: Int {
        checks.filter { $0.breachCount > 0 }.count
    }

    // status message that changes based on state
    private var statusText: String {
        if totalCount == 0 { return "No emails tracked yet" }
        if atRiskCount > 0 { return "\(atRiskCount) item(s) need attention" }
        return "No risks recorded"
    }

    // get the most recent check date across all checks
    private var lastCheckedText: String {
        guard let date = checks.compactMap(\.lastCheckedAt).max() else {
            return "Never"
        }
        // compact format so it doesn't wrap on small screens
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    // helper to build a metric card (title + value)
    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                // shrink text if it's too long
                .minimumScaleFactor(0.85)
        }
    }
}
