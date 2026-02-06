import SwiftUI
import SwiftData

struct WebAuditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WebScan.createdAt, order: .reverse) private var scans: [WebScan]

    @State private var isPresentingAddSheet = false
    
    private let sectionGradient = GuardianTheme.SectionColor.webAuditor.gradient

    var body: some View {
        Group {
            if scans.isEmpty {
                emptyStateView
            } else {
                List {
                    Section {
                        ForEach(scans) { scan in
                            NavigationLink {
                                WebScanDetailView(scan: scan)
                            } label: {
                                WebScanRow(scan: scan)
                            }
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
        .navigationTitle("Website Security Scanner")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .tint(GuardianTheme.SectionColor.webAuditor.primaryColor)
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            AddWebScanSheet { normalizedURL in
                let scan = WebScan(urlString: normalizedURL)
                modelContext.insert(scan)
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
                
                Image(systemName: "globe")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(sectionGradient)
            }
            
            VStack(spacing: 8) {
                Text("Scan Website Security")
                    .font(.title2.weight(.bold))
                
                Text("Check if websites use secure connections (HTTPS/TLS) and follow security best practices like HSTS and Content Security Policy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                isPresentingAddSheet = true
            } label: {
                Label("Add Website to Scan", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(GuardianTheme.SectionColor.webAuditor.primaryColor)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(scans[index])
        }
    }
}
