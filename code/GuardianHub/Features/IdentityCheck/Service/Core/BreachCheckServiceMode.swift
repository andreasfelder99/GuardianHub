import Foundation

enum BreachCheckServiceMode: String, CaseIterable, Identifiable {
    case automatic
    case live
    case stub

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .live: return "Live (HIBP)"
        case .stub: return "Mock (Stub)"
        }
    }
}
