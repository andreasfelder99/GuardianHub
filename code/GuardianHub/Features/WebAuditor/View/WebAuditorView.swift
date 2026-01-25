import SwiftUI
import SwiftData

struct WebAuditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WebScan.createdAt, order: .reverse) private var scans: [WebScan]

    @State private var isPresentingAddSheet = false

    var body: some View {
        Group {
            if scans.isEmpty {
                ContentUnavailableView(
                    "No Web Scans",
                    systemImage: "globe",
                    description: Text("Add a URL to start auditing TLS and key security headers.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(scans) { scan in
                        WebScanRow(scan: scan)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(scan)
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
        .navigationTitle("Web Auditor")
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
            AddWebScanSheet { normalizedURL in
                let scan = WebScan(urlString: normalizedURL)
                modelContext.insert(scan)
            }
        }
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(scans[index])
        }
    }
}
