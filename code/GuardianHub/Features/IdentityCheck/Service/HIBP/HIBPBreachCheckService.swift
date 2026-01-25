import Foundation

struct HIBPBreachCheckService: BreachCheckServicing {
    private let client: HIBPBreachedAccountRangeClient

    init(client: HIBPBreachedAccountRangeClient) {
        self.client = client
    }

    func check(emailAddress: String) async throws -> BreachCheckResult {
        // Hash + split into range parts (prefix/suffix)
        let parts = EmailHashing.rangeParts(forEmail: emailAddress)
        let prefix = parts.prefix
        let suffix = parts.suffix.uppercased()

        // Fetch range from HIBP (this can throw HIBPError, including rate limits)
        let rangeItems = try await client.fetchRange(prefix: prefix)

        // Match our suffix against returned HashSuffix entries
        // Response suffixes are expected to be hex; handle case-insensitively.
        let match = rangeItems.first { $0.hashSuffix.uppercased() == suffix }

        // Convert websites to breach descriptors
        let breaches: [BreachDescriptor]
        if let match {
            // Ensure stable order for UI/persistence; dedupe just in case.
            let uniqueSorted = Array(Set(match.websites)).sorted()
            breaches = uniqueSorted.map {
                BreachDescriptor(name: $0, occurredAt: nil, addedAt: nil)
            }
        } else {
            breaches = []
        }

        return BreachCheckResult(checkedAt: .now, breaches: breaches)
    }
}
