import SwiftUI

struct WebScanRow: View {
    let scan: WebScan
    
    private var statusGradient: LinearGradient {
        if scan.lastScannedAt == nil {
            return GuardianTheme.StatusGradient.neutral.gradient
        }
        return scan.isTLSValid ? GuardianTheme.StatusGradient.success.gradient : GuardianTheme.StatusGradient.warning.gradient
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(statusGradient.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(URLNormalizer.displayDomain(from: scan.urlString))
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if scan.lastScannedAt != nil {
                        Circle()
                            .fill(statusGradient)
                            .frame(width: 6, height: 6)
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if scan.lastScannedAt != nil {
                    Text("scanned")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        if scan.lastScannedAt == nil { return "globe" }
        return scan.isTLSValid ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
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
