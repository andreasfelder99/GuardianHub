import SwiftUI
import SwiftData

struct WebAuditorSummaryTile: View {
    @Query(sort: \WebScan.createdAt, order: .reverse) private var scans: [WebScan]

    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Tracked", value: "\(totalCount)")
                metric(title: "Last Scan", value: lastScannedText)
                metric(title: "Status", value: statusText)
            }
        }
        .padding(16)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)

                if let accent = accentColor {
                    Rectangle()
                        .fill(accent)
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderStyle, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Web Auditor", systemImage: "globe")
                    .font(.headline)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onOpen) {
                Label("Open", systemImage: "arrow.right")
            }
            .buttonStyle(.bordered)
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
        if totalCount == 0 { return "No sites audited yet" }
        if let latest = scans.sorted(by: { ($0.lastScannedAt ?? .distantPast) > ($1.lastScannedAt ?? .distantPast) }).first,
           latest.lastScannedAt != nil {
            return latest.isTLSValid ? "Last scan looks good" : "Last scan needs review"
        }
        return "Sites added, not scanned yet"
    }

    private var accentColor: Color? {
        guard totalCount > 0 else { return nil }
        // If the most recent scan indicates issues, show an accent.
        if statusText == "Review" { return .orange }
        return nil
    }

    private var borderStyle: AnyShapeStyle {
        if statusText == "Review" {
            return AnyShapeStyle(Color.orange.opacity(0.35))
        }
        return AnyShapeStyle(.quaternary)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}
