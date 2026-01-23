import Foundation

enum EmailValidator {
    static func isPlausibleEmail(_ value: String) -> Bool {
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard s.count >= 5, s.count <= 254 else { return false }

        let parts = s.split(separator: "@")
        guard parts.count == 2 else { return false }

        let local = parts[0]
        let domain = parts[1]

        guard !local.isEmpty, !domain.isEmpty else { return false }
        guard !s.contains(" ") else { return false }

        // Domain must contain at least one dot
        let domainParts = domain.split(separator: ".")
        guard domainParts.count >= 2 else { return false }

        guard let tld = domainParts.last, tld.count >= 2 else { return false }

        return true
    }
}
