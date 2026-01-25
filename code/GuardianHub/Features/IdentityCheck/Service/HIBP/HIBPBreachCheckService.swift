import Foundation

struct HIBPBreachCheckService: BreachCheckServicing {
    private let client: HIBPBreachedAccountClient

    init(client: HIBPBreachedAccountClient) {
        self.client = client
    }

    func check(emailAddress: String) async throws -> BreachCheckResult {
        let breaches = try await client.fetchBreaches(account: emailAddress)

        let descriptors = breaches
            .map { BreachDescriptor(name: $0.name, occurredAt: nil, addedAt: nil) }

        return BreachCheckResult(checkedAt: .now, breaches: descriptors)
    }
}
