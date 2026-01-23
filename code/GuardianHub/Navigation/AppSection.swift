import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case identityCheck

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .identityCheck: return "Identity Check"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .identityCheck: return "person.text.rectangle"
        }
    }
}
