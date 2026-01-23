import SwiftUI

struct AddBreachCheckSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String) -> Void

    @State private var emailAddress: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("New Breach Check")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { submit() }
                            .disabled(!EmailValidator.isPlausibleEmail(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 220)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 12) {
            Text("Email Address")
                .font(.headline)

            TextField("name@example.com", text: $emailAddress)
                .autocorrectionDisabled()

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
            Section("Email Address") {
                TextField("name@example.com", text: $emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        #endif
    }

    private func submit() {
        let trimmed = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard EmailValidator.isPlausibleEmail(trimmed) else {
            validationMessage = "Please enter a valid email address."
            return
        }
        onAdd(trimmed)
        dismiss()
    }
}
