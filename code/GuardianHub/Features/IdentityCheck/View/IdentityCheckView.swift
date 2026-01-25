import SwiftUI
import SwiftData

struct IdentityCheckView: View {
    @Environment(\.modelContext) private var modelContext
    // sorted by newest first
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

    @State private var isPresentingAddSheet = false

    var body: some View {
        Group {
            if checks.isEmpty {
                // empty state when no checks yet
                ContentUnavailableView(
                    "No Breach Checks",
                    systemImage: "person.text.rectangle",
                    description: Text("Add an email address to start tracking breach history.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(checks) { check in
                            NavigationLink {
                                BreachCheckDetailView(check: check)
                            } label: {
                                BreachCheckRow(check: check)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(check)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: delete)
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
                // create new check and save it
                let check = BreachCheck(emailAddress: email)
                modelContext.insert(check)
            }
        }
    }

    // handle swipe to delete
    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(checks[index])
        }
    }
}
