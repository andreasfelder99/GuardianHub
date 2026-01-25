import Foundation

protocol TLSAuditing: Sendable {
    func audit(url: URL) async throws -> TLSAuditResult
}
