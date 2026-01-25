import Foundation

struct TLSAuditResult: Sendable {
    let scannedAt: Date
    let isTrusted: Bool

    let certificateCommonName: String?
    let certificateIssuer: String?
    let certificateValidUntil: Date?

    let summary: String
}
