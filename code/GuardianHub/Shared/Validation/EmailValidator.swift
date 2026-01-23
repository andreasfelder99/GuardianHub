import Foundation

enum EmailValidator {
    // basic email validation - not super strict but catches most obvious mistakes
    static func isPlausibleEmail(_ value: String) -> Bool {
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // min/max length check (RFC says max is 254)
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

        // tld should be at least 2 chars
        guard let tld = domainParts.last, tld.count >= 2 else { return false }

        return true
    }
}
