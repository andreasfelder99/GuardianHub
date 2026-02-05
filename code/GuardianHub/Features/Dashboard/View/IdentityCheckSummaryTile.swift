import SwiftUI
import SwiftData

struct IdentityCheckSummaryTile: View {
    // get all checks, newest first
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

    // callback when user wants to open identity check section
    let onOpen: () -> Void
    
    private let sectionGradient = GuardianTheme.SectionColor.identityCheck.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()
                .overlay(sectionGradient.opacity(0.3))

            // grid layout for the 3 metrics
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Tracked", value: "\(totalCount)", highlight: false)
                metric(title: "At Risk", value: "\(atRiskCount)", highlight: atRiskCount > 0)
                metric(title: "Last Check", value: lastCheckedText, highlight: false)
            }
        }
        .padding(16)
        .background {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(sectionGradient.opacity(0.08))

                // Gradient accent bar
                Rectangle()
                    .fill(accentGradient)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .shadow(color: GuardianTheme.SectionColor.identityCheck.primaryColor.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(sectionGradient.opacity(0.25), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            // Gradient icon background
            ZStack {
                Circle()
                    .fill(sectionGradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Identity Check")
                    .font(.headline)

                // show status message based on current state
                HStack(spacing: 6) {
                    if atRiskCount > 0 {
                        PulsingDot(color: GuardianTheme.StatusGradient.warning.primaryColor, size: 6)
                    }
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // button to navigate to full identity check view
            Button(action: onOpen) {
                HStack(spacing: 4) {
                    Text("Open")
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(GuardianTheme.SectionColor.identityCheck.primaryColor)
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
    private func metric(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(highlight ? AnyShapeStyle(GuardianTheme.StatusGradient.warning.gradient) : AnyShapeStyle(.primary))
                .lineLimit(1)
                // shrink text if it's too long
                .minimumScaleFactor(0.85)
        }
    }

    private var accentGradient: LinearGradient {
        if atRiskCount > 0 {
            return GuardianTheme.StatusGradient.warning.gradient
        }
        return sectionGradient
    }
}
