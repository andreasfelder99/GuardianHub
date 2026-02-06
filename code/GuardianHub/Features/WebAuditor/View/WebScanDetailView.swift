import SwiftUI
import SwiftData

struct WebScanDetailView: View {
    @Environment(\.modelContext) private var modelContext

    private let headerAuditor: SecurityHeaderAuditing = SecurityHeaderAuditor()
    private let tlsAuditor: TLSAuditing = TLSAuditor()


    let scan: WebScan

    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var isPresentingExplanation = false


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

            Section {
                LabeledContent("Connection", value: scan.tlsSummary)
                LabeledContent("Certificate Trusted", value: scan.isTLSValid ? "Yes" : "No")
                LabeledContent("Domain", value: scan.certificateCommonName ?? "—")
                LabeledContent("Issued By", value: scan.certificateIssuer ?? "—")
                LabeledContent(
                    "Expires",
                    value: scan.certificateValidUntil?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                )
            } header: {
                Text("HTTPS Certificate")
            } footer: {
                Text("A valid HTTPS certificate ensures your connection to this site is encrypted and verified.")
            }

            Section {
                LabeledContent("Overall", value: scan.headerSummary)
                LabeledContent("HSTS", value: scan.hasHSTS ? "Enabled" : "Not set")
                LabeledContent("Content Security", value: scan.hasCSP ? "Enabled" : "Not set")
            } header: {
                Text("Security Headers")
            } footer: {
                Text("HSTS forces secure connections. Content Security Policy (CSP) helps prevent cross-site scripting attacks.")
            }
        }
        .navigationTitle("Security Scan")
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
            ToolbarItem {
                Button {
                    isPresentingExplanation = true
                } label: {
                    Label("Why?", systemImage: "sparkles")
                }
            }
        }
        .sheet(isPresented: $isPresentingExplanation) {
            WebAuditExplanationSheet(snapshot: WebAuditScanSnapshot(from: scan))
        }
    }

    private var statusTitle: String {
        if scan.lastScannedAt == nil { return "Waiting for first scan" }
        return scan.isTLSValid ? "Connection is secure" : "Security issues detected"
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
                async let headerResult = headerAuditor.audit(url: url)
                async let tlsResult = tlsAuditor.audit(url: url)

                let (headers, tls) = try await (headerResult, tlsResult)

                await MainActor.run {
                    // Use the most recent scan timestamp among sub-scans
                    scan.lastScannedAt = max(headers.scannedAt, tls.scannedAt)

                    // Headers
                    scan.hasHSTS = headers.hasHSTS
                    scan.hasCSP = headers.hasCSP
                    scan.headerSummary = headers.summary

                    // TLS
                    scan.isTLSValid = tls.isTrusted
                    scan.tlsSummary = tls.summary
                    scan.certificateCommonName = tls.certificateCommonName
                    scan.certificateIssuer = tls.certificateIssuer
                    scan.certificateValidUntil = tls.certificateValidUntil

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
