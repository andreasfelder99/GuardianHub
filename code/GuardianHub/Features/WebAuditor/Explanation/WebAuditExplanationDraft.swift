import Foundation
import FoundationModels

@Generable
struct WebAuditExplanationDraft: Sendable, Codable, Hashable {
    var headline: String
    var keyPoints: [String]
    var nextSteps: [String]
    var whyTLSIsTrusted: String?
}
