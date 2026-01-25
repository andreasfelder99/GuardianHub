import Foundation

struct SecurityHeaderAuditResult: Sendable {
    let scannedAt: Date

    let hasHSTS: Bool
    let hasCSP: Bool

    let hasXContentTypeOptions: Bool
    let hasXFrameOptions: Bool
    let hasReferrerPolicy: Bool
    let hasPermissionsPolicy: Bool

    /// Short summary for list/detail display.
    let summary: String
}
