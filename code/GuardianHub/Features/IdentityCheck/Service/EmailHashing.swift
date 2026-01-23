import Foundation
import CryptoKit

enum EmailHashing {
    // HIBP normalizes email addresses case-insensitively. We also trim whitespace.
    static func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    // SHA-1 hex string (40 chars), uppercase to align with HIBP-style formatting.
    static func sha1Hex(of normalizedEmail: String) -> String {
        let data = Data(normalizedEmail.utf8)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02X", $0) }.joined()
    }

    // Returns (prefix, suffix) where prefix length is 6 chars (per breached account range API usage).
    static func rangeParts(forEmail email: String) -> (prefix: String, suffix: String) {
        let normalized = normalizeEmail(email)
        let full = sha1Hex(of: normalized)
        let prefix = String(full.prefix(6))
        let suffix = String(full.dropFirst(6))
        return (prefix, suffix)
    }
}
