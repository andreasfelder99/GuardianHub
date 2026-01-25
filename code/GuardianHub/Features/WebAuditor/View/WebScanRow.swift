import SwiftUI

struct WebScanRow: View {
    let scan: WebScan

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.urlString)
                    .font(.headline)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(trailing)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        if scan.lastScannedAt == nil { return "circle.dashed" }
        return scan.isTLSValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var iconColor: Color {
        if scan.lastScannedAt == nil { return .secondary }
        return scan.isTLSValid ? .secondary : .orange
    }

    private var subtitle: String {
        if scan.lastScannedAt == nil {
            return "Not scanned yet"
        }
        return scan.tlsSummary
    }

    private var trailing: String {
        guard let date = scan.lastScannedAt else { return "Never" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
