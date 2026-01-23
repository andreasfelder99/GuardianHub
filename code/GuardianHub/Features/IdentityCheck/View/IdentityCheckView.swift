import SwiftUI
import SwiftData

struct IdentityCheckView: View {
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

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
    }
}