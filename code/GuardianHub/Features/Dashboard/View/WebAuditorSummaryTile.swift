import SwiftUI
import SwiftData

struct WebAuditorSummaryTile: View {
    @Query(sort: \WebScan.createdAt, order: .reverse) private var scans: [WebScan]

    let onOpen: () -> Void
    
    private let sectionGradient = GuardianTheme.SectionColor.webAuditor.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()
                .overlay(sectionGradient.opacity(0.3))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Sites", value: "\(totalCount)", highlight: false)
                metric(title: "Last Scan", value: lastScannedText, highlight: false)
                statusMetric
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
            .shadow(color: GuardianTheme.SectionColor.webAuditor.primaryColor.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(sectionGradient.opacity(0.25), lineWidth: 1)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Gradient icon background
                ZStack {
                    Circle()
                        .fill(sectionGradient)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Website Security")
                        .font(.headline)

                    HStack(spacing: 6) {
                        if statusText == "Review" {
                            PulsingDot(color: GuardianTheme.StatusGradient.warning.primaryColor, size: 6)
                        }
                        Text(subtitleText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onOpen) {
                    HStack(spacing: 4) {
                        Text("Open")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.bordered)
                .tint(GuardianTheme.SectionColor.webAuditor.primaryColor)
            }
            
            Text("Verify HTTPS certificates and security headers on websites you use.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.flexible(minimum: 90), alignment: .leading),
            GridItem(.flexible(minimum: 90), alignment: .leading)
        ]
    }

    private var totalCount: Int { scans.count }

    private var lastScannedAt: Date? {
        scans.compactMap(\.lastScannedAt).max()
    }

    private var lastScannedText: String {
        guard let date = lastScannedAt else { return "Never" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var statusText: String {
        guard let latest = scans.sorted(by: { ($0.lastScannedAt ?? .distantPast) > ($1.lastScannedAt ?? .distantPast) }).first,
              latest.lastScannedAt != nil else {
            return "Never"
        }
        return latest.isTLSValid ? "OK" : "Review"
    }

    private var subtitleText: String {
        if totalCount == 0 { return "No websites scanned yet" }
        if let latest = scans.sorted(by: { ($0.lastScannedAt ?? .distantPast) > ($1.lastScannedAt ?? .distantPast) }).first,
           latest.lastScannedAt != nil {
            return latest.isTLSValid ? "Connection secure" : "Security issues found"
        }
        return "Websites added, scan pending"
    }

    private var accentGradient: LinearGradient {
        if statusText == "Review" {
            return GuardianTheme.StatusGradient.warning.gradient
        }
        return sectionGradient
    }

    private func metric(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(highlight ? AnyShapeStyle(GuardianTheme.StatusGradient.warning.gradient) : AnyShapeStyle(.primary))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
    
    private var statusMetric: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Status")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 6) {
                Circle()
                    .fill(statusText == "OK" ? GuardianTheme.StatusGradient.success.gradient : (statusText == "Review" ? GuardianTheme.StatusGradient.warning.gradient : GuardianTheme.StatusGradient.neutral.gradient))
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        statusText == "OK" ? AnyShapeStyle(GuardianTheme.StatusGradient.success.gradient) :
                        (statusText == "Review" ? AnyShapeStyle(GuardianTheme.StatusGradient.warning.gradient) : AnyShapeStyle(.primary))
                    )
            }
        }
    }
}
