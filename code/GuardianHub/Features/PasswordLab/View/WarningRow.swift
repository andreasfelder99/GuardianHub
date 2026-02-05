import SwiftUI

struct WarningsCard: View {
    let warnings: [PasswordWarning]
    
    private let sectionGradient = GuardianTheme.SectionColor.passwordLab.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: warnings.isEmpty ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.headline)
                    .foregroundStyle(warnings.isEmpty ? GuardianTheme.StatusGradient.success.gradient : GuardianTheme.StatusGradient.warning.gradient)
                
                Text("Warnings & Patterns")
                    .font(.headline)
                
                Spacer()
                
                if !warnings.isEmpty {
                    Text("\(warnings.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background {
                            Circle()
                                .fill(GuardianTheme.StatusGradient.warning.gradient)
                        }
                }
            }
            
            if warnings.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GuardianTheme.StatusGradient.success.gradient.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(GuardianTheme.StatusGradient.success.gradient)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Looking good!")
                            .font(.subheadline.weight(.semibold))
                        Text("No patterns or weaknesses detected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(warnings) { warning in
                        WarningRow(warning: warning)
                    }
                }
            }
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                
                if !warnings.isEmpty {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(GuardianTheme.StatusGradient.warning.gradient.opacity(0.04))
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    warnings.isEmpty ? sectionGradient.opacity(0.15) : GuardianTheme.StatusGradient.warning.gradient.opacity(0.25),
                    lineWidth: 1
                )
        }
    }
}

private struct WarningRow: View {
    let warning: PasswordWarning

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity icon with colored background
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(gradientForSeverity(warning.severity).opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: iconName(for: warning.severity))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(gradientForSeverity(warning.severity))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.subheadline.weight(.semibold))

                Text(warning.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(gradientForSeverity(warning.severity).opacity(0.06))
        }
        .accessibilityElement(children: .combine)
    }

    private func iconName(for severity: PasswordWarningSeverity) -> String {
        switch severity {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    private func gradientForSeverity(_ severity: PasswordWarningSeverity) -> LinearGradient {
        switch severity {
        case .info:
            return LinearGradient(colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warning:
            return GuardianTheme.StatusGradient.warning.gradient
        case .critical:
            return GuardianTheme.StatusGradient.danger.gradient
        }
    }
}
