import Foundation
import FoundationModels

@Generable
struct WebAuditExplanation: Sendable, Codable, Hashable {
    var headline: String
    var riskLevel: RiskLevel
    var keyPoints: [String]
    var nextSteps: [String]
    var whyTLSIsTrusted: String?

    @Generable
    enum RiskLevel: String, Codable, Sendable, Hashable {
        case ok
        case review
        case high
    }
}
//TODO rename nextSteps to why can i still trust this site?