import SwiftUI

struct PasswordLabSummaryTile: View {
    let onOpen: () -> Void
    
    private let sectionGradient = GuardianTheme.SectionColor.passwordLab.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()
                .overlay(sectionGradient.opacity(0.3))

            description
        }
        .padding(16)
        .background {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(sectionGradient.opacity(0.08))

                Rectangle()
                    .fill(sectionGradient)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .shadow(color: GuardianTheme.SectionColor.passwordLab.primaryColor.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(sectionGradient.opacity(0.25), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(sectionGradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "key.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Password Lab")
                    .font(.headline)

                Text("Test password strength instantly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            .tint(GuardianTheme.SectionColor.passwordLab.primaryColor)
        }
    }

    private var description: some View {
        HStack(spacing: 12) {
            featureTag(icon: "speedometer", text: "Real-time analysis")
            featureTag(icon: "hand.raised.fill", text: "100% private")
        }
    }
    
    private func featureTag(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(sectionGradient)
            
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(sectionGradient.opacity(0.1))
        }
    }
}
