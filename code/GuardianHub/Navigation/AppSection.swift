import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case identityCheck
    case webAuditor
    case privacyGuard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .identityCheck: return "Identity Check"
        case .webAuditor: return "Web Auditor"
        case .privacyGuard: return "Privacy Guard"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .identityCheck: return "person.text.rectangle"
        case .webAuditor: return "globe"
        case .privacyGuard: return "shield.lefthalf.filled"
        }
    }
}
