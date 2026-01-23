import Foundation

enum EmailValidator {
    static func isPlausibleEmail(_ value: String) -> Bool {
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count >= 3, s.count <= 254 else { return false }
        guard let at = s.firstIndex(of: "@") else { return false }

        let local = s[..<at]
        let domain = s[s.index(after: at)...]

        guard !local.isEmpty, !domain.isEmpty else { return false }
        guard domain.contains(".") else { return false }
        guard !s.contains(" ") else { return false }

        return true
    }
}