import Foundation

struct WebAuditScanSnapshot: Sendable, Codable, Hashable {
    let urlString: String
    let scannedAt: Date?

    let tlsSummary: String
    let isTLSValid: Bool
    let certificateCommonName: String?
    let certificateIssuer: String?
    let certificateValidUntil: Date?
    let tlsDetailsAvailable: Bool
    let tlsMetadataUnavailableIsNormal: Bool


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

        #if os(iOS)
        // Do not feed "unknown" into the model; it's a platform limitation.
        self.certificateIssuer = scan.certificateIssuer ?? "Not available on iOS"
        self.certificateValidUntil = scan.certificateValidUntil // keep nil; prompt renders "not available"
        #else
        self.certificateIssuer = scan.certificateIssuer
        self.certificateValidUntil = scan.certificateValidUntil
        #endif

        self.headerSummary = scan.headerSummary
        self.hasHSTS = scan.hasHSTS
        self.hasCSP = scan.hasCSP

        #if os(iOS)
        self.platformNote = "If you need full certificate details, use the macOS app."
        #else
        self.platformNote = nil
        #endif

        #if os(macOS)
        self.tlsDetailsAvailable = true
        #else
        self.tlsDetailsAvailable = false
        #endif

        #if os(iOS)
        self.tlsMetadataUnavailableIsNormal = true
        #else
        self.tlsMetadataUnavailableIsNormal = false
        #endif
    }
}
