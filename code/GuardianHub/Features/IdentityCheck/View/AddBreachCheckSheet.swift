import SwiftUI

struct AddBreachCheckSheet: View {
    @Environment(\.dismiss) private var dismiss

    // callback when user adds a valid email
    let onAdd: (String) -> Void

    @State private var emailAddress: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add Email to Monitor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        // disable add button if email is invalid
                        Button("Add") { submit() }
                            .disabled(!EmailValidator.isPlausibleEmail(emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
        }
        #if os(macOS)
        // make it a bit bigger on mac
        .frame(minWidth: 420, minHeight: 220)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        // simpler layout for mac
        VStack(alignment: .leading, spacing: 12) {
            Text("Email Address")
                .font(.headline)
            
            Text("We'll check if this email has appeared in any known data breaches.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
        // use form on iOS for better keyboard handling
        Form {
            Section {
                TextField("name@example.com", text: $emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Email Address")
            } footer: {
                Text("We'll check if this email has appeared in any known data breaches.")
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
