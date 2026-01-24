import Foundation
/**
 * Stub implementation of the BreachCheckServicing protocol.
 * This service is used to simulate the breach check service.
 * It is used to test the breach check service without relying on a real service.
 */
 
struct StubBreachCheckService: BreachCheckServicing {
    func check(emailAddress: String) async throws -> BreachCheckResult {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 450_000_000)

        let lower = emailAddress.lowercased()
        let breaches: [BreachDescriptor]

        if lower.contains("test") || lower.contains("pwn") {
            breaches = [
                BreachDescriptor(
                    name: "ExampleBreach",
                    occurredAt: Date(timeIntervalSince1970: 1_500_000_000),
                    addedAt: Date(timeIntervalSince1970: 1_600_000_000)
                ),
                BreachDescriptor(
                    name: "DemoLeak",
                    occurredAt: Date(timeIntervalSince1970: 1_650_000_000),
                    addedAt: Date(timeIntervalSince1970: 1_680_000_000)
                )
            ]
        } else {
            breaches = []
        }

        return BreachCheckResult(
            checkedAt: .now,
            breaches: breaches
        )
    }
}
