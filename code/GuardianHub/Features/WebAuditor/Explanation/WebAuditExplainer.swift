import Foundation

enum WebAuditExplainer {
    static func bestAvailable() -> any WebAuditExplanationBuilding {
        // Prefer Foundation Models explainer; it will self-fallback if unavailable.
        return FoundationModelsWebAuditExplainer()
    }
}
