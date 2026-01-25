import SwiftUI
import SwiftData

struct WebScanDetailView: View {
    @Environment(\.modelContext) private var modelContext

    private let headerAuditor: SecurityHeaderAuditing = SecurityHeaderAuditor()

    let scan: WebScan

    @State private var isRunning = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    Label(statusTitle, systemImage: statusIcon)
                    Spacer()
                    Text(statusBadge)
                        .foregroundStyle(statusColor)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Target") {
                LabeledContent("URL", value: scan.urlString)
                LabeledContent(
                    "Created",
                    value: scan.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
                LabeledContent(
                    "Last Scanned",
                    value: scan.lastScannedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
                )
            }

            Section("TLS") {
                LabeledContent("Status", value: scan.tlsSummary)
                LabeledContent("Trusted", value: scan.isTLSValid ? "Yes" : "No")
                LabeledContent("Common Name", value: scan.certificateCommonName ?? "—")
                LabeledContent("Issuer", value: scan.certificateIssuer ?? "—")
                LabeledContent(
                    "Valid Until",
                    value: scan.certificateValidUntil?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                )
            }

            Section("Security Headers") {
                LabeledContent("Summary", value: scan.headerSummary)
                LabeledContent("HSTS", value: scan.hasHSTS ? "Present" : "Missing")
                LabeledContent("CSP", value: scan.hasCSP ? "Present" : "Missing")
            }
        }
        .navigationTitle("Web Scan")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    runScan()
                } label: {
                    if isRunning {
                        ProgressView()
                    } else {
                        Label("Run Scan", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRunning)
            }
        }
    }

    private var statusTitle: String {
        if scan.lastScannedAt == nil { return "Not scanned yet" }
        return scan.isTLSValid ? "No critical issues found" : "Issues detected"
    }

    private var statusIcon: String {
        if scan.lastScannedAt == nil { return "circle.dashed" }
        return scan.isTLSValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var statusBadge: String {
        if scan.lastScannedAt == nil { return "Pending" }
        return scan.isTLSValid ? "OK" : "Review"
    }

    private var statusColor: Color {
        if scan.lastScannedAt == nil { return .secondary }
        return scan.isTLSValid ? .secondary : .orange
    }

    private func runScan() {
        errorMessage = nil

        guard let normalized = URLNormalizer.normalizeForWebScan(scan.urlString),
            let url = URL(string: normalized) else {
            errorMessage = "Invalid URL. Please edit the entry and try again."
            return
        }

        isRunning = true

        Task {
            do {
                let headerResult = try await headerAuditor.audit(url: url)

                await MainActor.run {
                    scan.lastScannedAt = headerResult.scannedAt

                    scan.hasHSTS = headerResult.hasHSTS
                    scan.hasCSP = headerResult.hasCSP

                    scan.headerSummary = headerResult.summary

                    if scan.tlsSummary == "Not scanned" {
                        scan.tlsSummary = "Pending TLS scan"
                    }

                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Scan failed: \(error.localizedDescription)"
                    isRunning = false
                }
            }
        }
    }
}
