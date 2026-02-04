import SwiftUI

struct WarningsCard: View {
    let warnings: [PasswordWarning]

    var body: some View {
        GroupBox {
            if warnings.isEmpty {
                HStack {
                    Label("No warnings", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 2)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(warnings) { warning in
                        WarningRow(warning: warning)

                        if warning.id != warnings.last?.id {
                            Divider()
                        }
                    }
                }
            }
        } label: {
            Text("Warnings & Patterns")
        }
    }
}

private struct WarningRow: View {
    let warning: PasswordWarning

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: iconName(for: warning.severity))
                    .imageScale(.medium)
                    .foregroundStyle(tint(for: warning.severity))

                Text(warning.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()
            }

            Text(warning.detail)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private func iconName(for severity: PasswordWarningSeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        }
    }

    private func tint(for severity: PasswordWarningSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
