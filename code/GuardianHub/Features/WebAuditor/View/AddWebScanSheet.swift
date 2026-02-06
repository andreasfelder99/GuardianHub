import SwiftUI

struct AddWebScanSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String) -> Void

    @State private var urlInput: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add Website")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { submit() }
                            .disabled(URLNormalizer.normalizeForWebScan(urlInput) == nil)
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 260)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 12) {
            Text("Website URL")
                .font(.headline)
            
            Text("We'll check the site's HTTPS certificate and security headers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("example.com", text: $urlInput)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Text("You can enter just the domain—https:// will be added automatically.")
                .font(.footnote)
                .foregroundStyle(.tertiary)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        #else
        Form {
            Section {
                TextField("example.com", text: $urlInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Website URL")
            } footer: {
                Text("We'll check the site's HTTPS certificate and security headers. You can enter just the domain—https:// will be added automatically.")
            }
        }
        #endif
    }

    private func submit() {
        guard let normalized = URLNormalizer.normalizeForWebScan(urlInput) else {
            validationMessage = "Please enter a valid URL (e.g., example.com)."
            return
        }
        onAdd(normalized)
        dismiss()
    }
}
