import Foundation
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case identityCheck
    case webAuditor
    case privacyGuard
    case passwordLab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .identityCheck: return "Breach Monitor"
        case .webAuditor: return "Web Security"
        case .privacyGuard: return "Photo Privacy"
        case .passwordLab: return "Passwords"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .identityCheck: return "person.text.rectangle"
        case .webAuditor: return "globe"
        case .privacyGuard: return "shield.lefthalf.filled"
        case .passwordLab: return "key.viewfinder"
        }
    }
    
    var themeColor: GuardianTheme.SectionColor {
        switch self {
        case .dashboard: return .dashboard
        case .identityCheck: return .identityCheck
        case .webAuditor: return .webAuditor
        case .privacyGuard: return .privacyGuard
        case .passwordLab: return .passwordLab
        }
    }
    
    var gradient: LinearGradient {
        themeColor.gradient
    }
    
    var primaryColor: Color {
        themeColor.primaryColor
    }
}
