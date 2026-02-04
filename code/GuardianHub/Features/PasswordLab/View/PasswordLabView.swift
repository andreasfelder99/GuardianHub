import SwiftUI

struct PasswordLabView: View {
    @State private var model = PasswordLabModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                passwordEntryCard

                StrengthMeterCard(result: model.result)

                EntropyBreakdownCard(result: model.result)

                WarningsCard(warnings: model.result.warnings)

                privacyFootnote
            }
            .padding()
        }
        .navigationTitle("Password Lab")
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password Strength (Offline)")
                .font(.title2.weight(.semibold))
            Text("Transparent rules, real-time feedback, and helpful explanations. Nothing is stored or sent.")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Entry

    private var passwordEntryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Test Password", systemImage: "key.fill")
                        .font(.headline)

                    Spacer()

                    Toggle(isOn: $model.isRevealed) {
                        Text("Reveal")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityLabel(model.isRevealed ? "Hide password" : "Reveal password")
                }

                VStack(spacing: 10) {
                    if model.isRevealed {
                        TextField("Type a password…", text: $model.password)
                            .textInputAutocapitalization(.never)
#if os(iOS)
                            .textContentType(.newPassword)
                            .keyboardType(.asciiCapable)
#endif
                            .autocorrectionDisabled()
                            .font(.body.monospaced())
                    } else {
                        SecureField("Type a password…", text: $model.password)
                            .textInputAutocapitalization(.never)
#if os(iOS)
                            .textContentType(.newPassword)
#endif
                            .autocorrectionDisabled()
                            .font(.body.monospaced())
                    }

                    HStack {
                        Text("Length: \(model.result.passwordLength)")
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            model.clear()
                        } label: {
                            Label("Clear", systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(model.password.isEmpty)
                    }
                }
            }
        } label: {
            Text("Input")
        }
    }

    // MARK: - Privacy

    private var privacyFootnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Privacy", systemImage: "hand.raised.fill")
                .font(.headline)
            Text("Your password stays in memory only for analysis. GuardianHub does not store or log it.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}
