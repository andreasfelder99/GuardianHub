import SwiftUI

struct PasswordLabView: View {
    @State private var model = PasswordLabModel()
    
    private let sectionGradient = GuardianTheme.SectionColor.passwordLab.gradient

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                passwordEntryCard

                StrengthMeterCard(result: model.result)

                EntropyBreakdownCard(result: model.result)

                WarningsCard(warnings: model.result.warnings)

                privacyFootnote
            }
            .padding()
        }
        .navigationTitle("Password Strength Tester")
        .scrollIndicators(.hidden)
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        #if os(macOS)
        .frame(minWidth: 400)
        #endif
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(sectionGradient)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "key.viewfinder")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test Your Password")
                        .font(.title2.weight(.bold))
                    
                    Text("See how strong your password really is. Analysis happens locally—nothing leaves your device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Entry

    private var passwordEntryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            passwordEntryHeader
            passwordInputSection
        }
        .padding(16)
        .background(passwordCardBackground)
        .overlay(passwordCardOverlay)
    }
    
    private var passwordEntryHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .font(.headline)
                    .foregroundStyle(sectionGradient)
                
                Text("Test Password")
                    .font(.headline)
            }

            Spacer()

            Toggle(isOn: $model.isRevealed) {
                Text("Reveal")
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel(model.isRevealed ? "Hide password" : "Reveal password")
        }
    }
    
    private var passwordInputSection: some View {
        VStack(spacing: 12) {
            passwordField
            passwordLengthRow
        }
    }
    
    @ViewBuilder
    private var passwordField: some View {
        let borderColor = model.password.isEmpty ? Color.secondary.opacity(0.2) : GuardianTheme.SectionColor.passwordLab.primaryColor.opacity(0.5)
        
        if model.isRevealed {
            TextField("Type a password…", text: $model.password)
                #if os(iOS)
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                #endif
                .autocorrectionDisabled()
                .font(.body.monospaced())
                .padding(12)
                .background(passwordFieldBackground(borderColor: borderColor))
        } else {
            SecureField("Type a password…", text: $model.password)
                #if os(iOS)
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .font(.body.monospaced())
                .padding(12)
                .background(passwordFieldBackground(borderColor: borderColor))
        }
    }
    
    private func passwordFieldBackground(borderColor: Color) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.background)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            }
    }
    
    private var passwordLengthRow: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Length:")
                    .foregroundStyle(.secondary)
                Text("\(model.result.passwordLength)")
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(model.result.passwordLength > 0 ? GuardianTheme.SectionColor.passwordLab.primaryColor : .secondary)
            }

            Spacer()

            Button {
                model.clear()
            } label: {
                Label("Clear", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(GuardianTheme.SectionColor.passwordLab.primaryColor)
            .disabled(model.password.isEmpty)
        }
    }
    
    private var passwordCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private var passwordCardOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(sectionGradient.opacity(0.2), lineWidth: 1)
    }

    // MARK: - Privacy

    private var privacyFootnote: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GuardianTheme.StatusGradient.success.gradient.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GuardianTheme.StatusGradient.success.gradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy")
                    .font(.subheadline.weight(.semibold))
                Text("Your password stays in memory only for analysis. GuardianHub does not store or log it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }
}
