import Foundation

struct HIBPBreachedAccountClient: Sendable {
    private let config: HIBPConfiguration
    private let session: URLSession

    init(config: HIBPConfiguration, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    /// GET https://haveibeenpwned.com/api/v3/breachedaccount/{account}
    func fetchBreaches(account: String) async throws -> [HIBPBreachName] {
        let trimmed = account.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://haveibeenpwned.com/api/v3/breachedaccount/\(encoded)") else {
            throw HIBPError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(config.apiKey, forHTTPHeaderField: "hibp-api-key")
        request.setValue(config.userAgent, forHTTPHeaderField: "user-agent")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HIBPError.invalidResponse
        }

        if http.statusCode == 429 {
            let retryAfter = Self.parseRetryAfterSeconds(from: http) ?? 1
            throw HIBPError.rateLimited(retryAfterSeconds: retryAfter)
        }

        if http.statusCode == 404 {
            // Account not found -> not pwned
            return []
        }

        guard (200...299).contains(http.statusCode) else {
            throw HIBPError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([HIBPBreachName].self, from: data)
        } catch {
            throw HIBPError.decodingFailed
        }
    }

    private static func parseRetryAfterSeconds(from response: HTTPURLResponse) -> Int? {
        for (key, value) in response.allHeaderFields {
            guard String(describing: key).lowercased() == "retry-after" else { continue }
            if let s = value as? String, let i = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) { return i }
            if let i = value as? Int { return i }
            return nil
        }
        return nil
    }
}
