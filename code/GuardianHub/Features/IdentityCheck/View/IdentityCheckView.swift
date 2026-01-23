import SwiftUI
import SwiftData

struct IdentityCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

    @State private var isPresentingAddSheet = false

    var body: some View {
        List {
            if checks.isEmpty {
                ContentUnavailableView(
                    "No Breach Checks",
                    systemImage: "person.text.rectangle",
                    description: Text("Add an email address to start tracking breach history.")
                )
            } else {
                Section {
                    ForEach(checks) { check in
                        BreachCheckRow(check: check)
                    }
                }
            }
        }
        .navigationTitle("Identity Check")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            AddBreachCheckSheet { email in
                let check = BreachCheck(emailAddress: email)
                modelContext.insert(check)
            }
        }
    }
}