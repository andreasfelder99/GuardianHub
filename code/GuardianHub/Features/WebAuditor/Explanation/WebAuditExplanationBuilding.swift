import Foundation

protocol WebAuditExplanationBuilding: Sendable {
    func explain(snapshot: WebAuditScanSnapshot) async -> WebAuditExplanation
}
