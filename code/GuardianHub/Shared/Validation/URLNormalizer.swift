import Foundation

enum URLNormalizer {
    /// Returns a normalized absolute URL string suitable for storage and requests.
    /// - Adds https:// if no scheme is present.
    /// - Adds .com if the host doesn't have a TLD.
    static func normalizeForWebScan(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme: String
        if trimmed.contains("://") {
            withScheme = trimmed
        } else {
            withScheme = "https://\(trimmed)"
        }

        guard var url = URL(string: withScheme) else { return nil }
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return nil }
        guard var host = url.host, !host.isEmpty else { return nil }
        
        // Add .com if host doesn't have a TLD
        if !host.contains(".") && host.lowercased() != "localhost" && !isIPAddress(host) {
            host = "\(host).com"
            // Reconstruct URL with updated host
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.host = host
            guard let updatedURL = components?.url else { return nil }
            url = updatedURL
        }

        return url.absoluteString
    }
    
    /// Checks if a string is an IP address (IPv4 or IPv6)
    private static func isIPAddress(_ string: String) -> Bool {
        // Check for IPv4
        let ipv4Pattern = #"^(\d{1,3}\.){3}\d{1,3}$"#
        if string.range(of: ipv4Pattern, options: .regularExpression) != nil {
            return true
        }
        // Check for IPv6 (simplified - contains colons)
        if string.contains(":") {
            return true
        }
        return false
    }

    /// Returns the host (domain) portion of a URL for display, e.g. "apple.com" from "https://www.apple.com/path".
    /// Strips "www." if present. Falls back to the original string if the URL cannot be parsed.
    static func displayDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host, !host.isEmpty else {
            return urlString
        }
        let lower = host.lowercased()
        if lower.hasPrefix("www.") && host.count > 4 {
            return String(host[host.index(host.startIndex, offsetBy: 4)...])
        }
        return host
    }
}
