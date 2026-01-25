import Foundation
import FoundationModels
import Observation

@Observable
final class WebAuditExplanationViewModel {
    private(set) var explanation: WebAuditExplanation?
    private(set) var statusText: String = ""
    private(set) var isGenerating: Bool = false

    private let model = SystemLanguageModel.default
    private let explainer: any WebAuditExplanationBuilding

    init(explainer: any WebAuditExplanationBuilding = WebAuditExplainer.bestAvailable()) {
        self.explainer = explainer
        self.statusText = Self.statusString(for: model.availability)
    }

    func generate(from snapshot: WebAuditScanSnapshot) {
        guard !isGenerating else { return }

        isGenerating = true
        explanation = nil
        statusText = Self.statusString(for: model.availability)

        Task {
            let result = await explainer.explain(snapshot: snapshot)

            await MainActor.run {
                self.explanation = result
                self.isGenerating = false
            }
        }
    }

    private static func statusString(for availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "Using Apple Intelligence on-device model."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence is off. Using standard explanation."
        case .unavailable(.modelNotReady):
            return "Model is downloading or not ready. Using standard explanation."
        case .unavailable(.deviceNotEligible):
            return "Device not eligible. Using standard explanation."
        case .unavailable:
            return "Model unavailable. Using standard explanation."
        @unknown default:
            return "Model availability unknown. Using standard explanation."
        }
    }
}
