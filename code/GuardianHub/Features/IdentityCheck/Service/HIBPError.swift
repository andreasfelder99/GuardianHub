import Foundation

enum HIBPError: Error, LocalizedError, Sendable {
    case invalidResponse
    case httpStatus(Int)
    case rateLimited(retryAfterSeconds: Int)
    case decodingFailed
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Have I Been Pwned."
        case .httpStatus(let code):
            return "Have I Been Pwned returned HTTP \(code)."
        case .rateLimited(let seconds):
            return "Rate limit exceeded. Try again in \(seconds) seconds."
        case .decodingFailed:
            return "Failed to decode Have I Been Pwned response."
        case .missingAPIKey:
            return "HIBP API key is missing."
        }
    }
}
