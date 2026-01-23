import SwiftUI

struct AddBreachCheckSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String) -> Void

    @State private var emailAddress: String = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Email Address") {
                    TextField("name@example.com", text: $emailAddress)
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        #endif

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Add") { submit() }
                }
            }
            .navigationTitle("New Breach Check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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