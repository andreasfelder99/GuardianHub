import SwiftUI

struct AddWebScanSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String) -> Void

    @State private var urlInput: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("New Web Scan")
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

            TextField("example.com", text: $urlInput)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Text("Tip: You can paste without https:// — it will be added automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)

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
            Section("Website URL") {
                TextField("example.com", text: $urlInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Text("Tip: You can paste without https:// — it will be added automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
