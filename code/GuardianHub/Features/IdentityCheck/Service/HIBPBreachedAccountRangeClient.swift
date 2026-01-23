import Foundation

struct HIBPBreachedAccountRangeClient: Sendable {
    private let config: HIBPConfiguration
    private let session: URLSession

    init(config: HIBPConfiguration, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    /// GET https://haveibeenpwned.com/api/v3/breachedaccount/range/{prefix}
    func fetchRange(prefix: String) async throws -> [HIBPBreachedAccountRangeItem] {
        guard let url = URL(string: "https://haveibeenpwned.com/api/v3/breachedaccount/range/\(prefix)") else {
            throw HIBPError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Authenticated API uses hibp-api-key header
        request.setValue(config.apiKey, forHTTPHeaderField: "hibp-api-key")

        // Must properly identify User-Agent
        request.setValue(config.userAgent, forHTTPHeaderField: "user-agent")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HIBPError.invalidResponse
        }

        if http.statusCode == 429 {
            // HIBP returns retry-after header with seconds
            let retryAfter = Self.parseRetryAfterSeconds(from: http) ?? 1
            throw HIBPError.rateLimited(retryAfterSeconds: retryAfter)
        }

        guard (200...299).contains(http.statusCode) else {
            throw HIBPError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([HIBPBreachedAccountRangeItem].self, from: data)
        } catch {
            throw HIBPError.decodingFailed
        }
    }

    private static func parseRetryAfterSeconds(from response: HTTPURLResponse) -> Int? {
        // Header key is case-insensitive; URLResponse stores as AnyHashable.
        for (key, value) in response.allHeaderFields {
            guard String(describing: key).lowercased() == "retry-after" else { continue }
            if let s = value as? String, let i = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) { return i }
            if let i = value as? Int { return i }
            return nil
        }
        return nil
    }
}
