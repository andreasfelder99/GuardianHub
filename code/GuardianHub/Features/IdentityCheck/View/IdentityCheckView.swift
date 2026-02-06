import SwiftUI
import SwiftData

struct IdentityCheckView: View {
    @Environment(\.modelContext) private var modelContext
    // sorted by newest first
    @Query(sort: \BreachCheck.createdAt, order: .reverse) private var checks: [BreachCheck]

    @State private var isPresentingAddSheet = false
    
    private let sectionGradient = GuardianTheme.SectionColor.identityCheck.gradient

    var body: some View {
        Group {
            if checks.isEmpty {
                // Enhanced empty state
                emptyStateView
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
        .navigationTitle("Data Breach Monitor")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .tint(GuardianTheme.SectionColor.identityCheck.primaryColor)
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            AddBreachCheckSheet { email in
                // create new check and save it
                let check = BreachCheck(emailAddress: email)
                modelContext.insert(check)
            }
        }
        #if os(macOS)
        .frame(minWidth: 400)
        #endif
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(sectionGradient.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(sectionGradient)
            }
            
            VStack(spacing: 8) {
                Text("Monitor Your Digital Identity")
                    .font(.title2.weight(.bold))
                
                Text("Check if your email addresses have appeared in known data breaches. Stay informed when your credentials may have been exposed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                isPresentingAddSheet = true
            } label: {
                Label("Add Email to Monitor", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(GuardianTheme.SectionColor.identityCheck.primaryColor)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // handle swipe to delete
    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(checks[index])
        }
    }
}
