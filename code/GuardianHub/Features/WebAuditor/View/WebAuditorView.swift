import SwiftUI
import SwiftData

struct WebAuditorView: View {
    @Query(sort: \WebScan.createdAt, order: .reverse) private var scans: [WebScan]

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
                        }
                    }
                }
            }
        }
        .navigationTitle("Web Auditor")
    }
}
