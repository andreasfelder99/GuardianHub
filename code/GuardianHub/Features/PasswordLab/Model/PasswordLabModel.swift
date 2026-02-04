import Foundation
import Observation

@Observable
final class PasswordLabModel {

    // User input (never persisted, never logged)
    var password: String = "" {
        didSet {
            // Strip spaces – most password systems don't allow them
            let filtered = password.replacingOccurrences(of: " ", with: "")
            if filtered != password {
                password = filtered
                return // didSet will fire again with the filtered value
            }
            analyze()
        }
    }

    // UX
    var isRevealed: Bool = false

    // Output
    var result: PasswordAnalysisResult

    private let engine = PasswordAnalysisEngine()
    private var lastCategory: PasswordStrengthCategory?

    #if os(iOS)
    private let haptics = PasswordLabHaptics()
    #endif

    init() {
        let initial = PasswordAnalysisEngine().analyze("")
        self.result = initial
        self.lastCategory = initial.category

        #if os(iOS)
        haptics.prepare()
        #endif
    }

    func clear() {
        password = ""
        isRevealed = false
    }

    // MARK: - Private

    private func analyze() {
        let newResult = engine.analyze(password)
        result = newResult

        if lastCategory != newResult.category {
            #if os(iOS)
            haptics.playTransition(to: newResult.category)
            #endif
            lastCategory = newResult.category
        }
    }
}
