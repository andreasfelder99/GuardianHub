import Foundation

public enum PasswordStrengthCategory: String, CaseIterable, Sendable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case fair = "Fair"
    case strong = "Strong"

    public var systemImage: String {
        switch self {
        case .veryWeak: return "exclamationmark.triangle"
        case .weak: return "shield.lefthalf.filled"
        case .fair: return "shield"
        case .strong: return "checkmark.shield.fill"
        }
    }

    public var accessibilityLabel: String { rawValue }
}

public enum PasswordWarningSeverity: String, Sendable {
    case info
    case warning
    case critical
}

public struct PasswordWarning: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let severity: PasswordWarningSeverity

    public init(id: String, title: String, detail: String, severity: PasswordWarningSeverity) {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
    }
}

public struct EntropyComponent: Hashable, Sendable {
    public let label: String
    public let bits: Double

    public init(label: String, bits: Double) {
        self.label = label
        self.bits = bits
    }
}

public struct PasswordAnalysisResult: Hashable, Sendable {
    public let passwordLength: Int
    public let entropyBits: Double
    public let category: PasswordStrengthCategory
    /// 0...1 normalized for meters.
    public let meterValue: Double
    public let warnings: [PasswordWarning]
    /// Transparent breakdown components (baseline + adjustments).
    public let breakdown: [EntropyComponent]

    public init(
        passwordLength: Int,
        entropyBits: Double,
        category: PasswordStrengthCategory,
        meterValue: Double,
        warnings: [PasswordWarning],
        breakdown: [EntropyComponent]
    ) {
        self.passwordLength = passwordLength
        self.entropyBits = entropyBits
        self.category = category
        self.meterValue = meterValue
        self.warnings = warnings
        self.breakdown = breakdown
    }
}
