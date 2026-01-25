import Foundation

struct WebAuditScanSnapshot: Sendable, Codable, Hashable {
    let urlString: String
    let scannedAt: Date?

    let tlsSummary: String
    let isTLSValid: Bool
    let certificateCommonName: String?
    let certificateIssuer: String?
    let certificateValidUntil: Date?

    let headerSummary: String
    let hasHSTS: Bool
    let hasCSP: Bool

    #if os(iOS)
    let platformNote: String?
    #else
    let platformNote: String?
    #endif
}

extension WebAuditScanSnapshot {
    init(from scan: WebScan) {
        self.urlString = scan.urlString
        self.scannedAt = scan.lastScannedAt

        self.tlsSummary = scan.tlsSummary
        self.isTLSValid = scan.isTLSValid
        self.certificateCommonName = scan.certificateCommonName
        self.certificateIssuer = scan.certificateIssuer
        self.certificateValidUntil = scan.certificateValidUntil

        self.headerSummary = scan.headerSummary
        self.hasHSTS = scan.hasHSTS
        self.hasCSP = scan.hasCSP

        #if os(iOS)
        self.platformNote = "If you need full certificate details, use the macOS app."
        #else
        self.platformNote = nil
        #endif
    }
}
