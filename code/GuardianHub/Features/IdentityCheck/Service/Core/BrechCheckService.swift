import Foundation

/**
 * Result of a breach check.
 * Contains the date and time the check was performed, and the list of breaches found.
 */

struct BreachCheckResult: Sendable {
    let checkedAt: Date
    let breaches: [BreachDescriptor]
}

struct BreachDescriptor: Sendable, Hashable {
    let name: String
    let occurredAt: Date?
    let addedAt: Date?
}

protocol BreachCheckServicing: Sendable {
    func check(emailAddress: String) async throws -> BreachCheckResult
}
