import Foundation

protocol SecurityHeaderAuditing: Sendable {
    func audit(url: URL) async throws -> SecurityHeaderAuditResult
}
