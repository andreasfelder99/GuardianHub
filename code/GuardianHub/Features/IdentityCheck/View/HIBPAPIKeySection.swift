import SwiftUI

struct HIBPAPIKeySection: View {
    @State private var apiKeyInput: String = ""
    @State private var isKeyStored: Bool = (HIBPAPIKeyStore.load() != nil)
    @State private var feedbackMessage: String?

    var body: some View {
        Section("Have I Been Pwned API") {
            SecureField("API Key", text: $apiKeyInput)
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

            HStack {
                Button("Save Key") { save() }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Remove Key", role: .destructive) { remove() }
                    .disabled(!isKeyStored)
            }

            statusRow

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Refresh status when the view appears.
            isKeyStored = (HIBPAPIKeyStore.load() != nil)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: isKeyStored ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isKeyStored ? Color.secondary : Color.orange)

            Text(isKeyStored ? "API key stored in Keychain." : "No API key stored. Live mode will not work.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func save() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let ok = HIBPAPIKeyStore.save(trimmed)
        isKeyStored = (HIBPAPIKeyStore.load() != nil)

        if ok {
            apiKeyInput = "" // do not keep secrets in memory longer than necessary
            feedbackMessage = "Saved."
        } else {
            feedbackMessage = "Failed to save key. Please try again."
        }
    }

    private func remove() {
        let ok = HIBPAPIKeyStore.remove()
        isKeyStored = (HIBPAPIKeyStore.load() != nil)

        feedbackMessage = ok ? "Removed." : "Failed to remove key. Please try again."
    }
}
