import Foundation

struct SecurityHeaderAuditor: SecurityHeaderAuditing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func audit(url: URL) async throws -> SecurityHeaderAuditResult {
        // Prefer HEAD to reduce payload; fall back to GET if server rejects HEAD.
        let response = try await headThenGet(url: url)

        let headers = normalizedHeaders(from: response)

        let hasHSTS = headers["strict-transport-security"] != nil
        let hasCSP = headers["content-security-policy"] != nil

        let hasXContentTypeOptions = headers["x-content-type-options"] != nil
        let hasXFrameOptions = headers["x-frame-options"] != nil
        let hasReferrerPolicy = headers["referrer-policy"] != nil
        let hasPermissionsPolicy = headers["permissions-policy"] != nil || headers["feature-policy"] != nil

        let summary = Self.makeSummary(
            hasHSTS: hasHSTS,
            hasCSP: hasCSP,
            hasXContentTypeOptions: hasXContentTypeOptions,
            hasXFrameOptions: hasXFrameOptions,
            hasReferrerPolicy: hasReferrerPolicy,
            hasPermissionsPolicy: hasPermissionsPolicy
        )

        return SecurityHeaderAuditResult(
            scannedAt: .now,
            hasHSTS: hasHSTS,
            hasCSP: hasCSP,
            hasXContentTypeOptions: hasXContentTypeOptions,
            hasXFrameOptions: hasXFrameOptions,
            hasReferrerPolicy: hasReferrerPolicy,
            hasPermissionsPolicy: hasPermissionsPolicy,
            summary: summary
        )
    }

    private func headThenGet(url: URL) async throws -> HTTPURLResponse {
        do {
            return try await request(url: url, method: "HEAD")
        } catch {
            // Some servers disallow HEAD; try GET.
            return try await request(url: url, method: "GET")
        }
    }

    private func request(url: URL, method: String) async throws -> HTTPURLResponse {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15

        let (_, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Consider any 2xx/3xx a usable header response.
        guard (200...399).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return http
    }

    private func normalizedHeaders(from response: HTTPURLResponse) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in response.allHeaderFields {
            let key = String(describing: k).lowercased()
            let value = String(describing: v)
            result[key] = value
        }
        return result
    }

    private static func makeSummary(
        hasHSTS: Bool,
        hasCSP: Bool,
        hasXContentTypeOptions: Bool,
        hasXFrameOptions: Bool,
        hasReferrerPolicy: Bool,
        hasPermissionsPolicy: Bool
    ) -> String {
        var missing: [String] = []

        if !hasHSTS { missing.append("HSTS") }
        if !hasCSP { missing.append("CSP") }
        if !hasXContentTypeOptions { missing.append("XCTO") }
        if !hasXFrameOptions { missing.append("XFO") }
        if !hasReferrerPolicy { missing.append("Referrer-Policy") }
        if !hasPermissionsPolicy { missing.append("Permissions-Policy") }

        if missing.isEmpty {
            return "Headers: strong baseline"
        } else if missing.count <= 2 {
            return "Missing: " + missing.joined(separator: ", ")
        } else {
            return "Missing \(missing.count) recommended headers"
        }
    }
}
