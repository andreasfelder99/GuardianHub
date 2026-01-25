import SwiftUI

struct WebAuditorView: View {
    var body: some View {
        ContentUnavailableView(
            "Web Auditor",
            systemImage: "globe",
            description: Text("Coming next: scan TLS certificate details and key security headers.")
        )
        .navigationTitle("Web Auditor")
    }
}
