import Foundation
import SwiftData

/**
 * Store for breach checks.
 */

enum BreachCheckStore {

    static func add(emailAddress: String, in modelContext: ModelContext) {
        let check = BreachCheck(emailAddress: emailAddress)
        modelContext.insert(check)
    }

    static func apply(
        _ result: BreachCheckResult,
        to check: BreachCheck
    ) {
        // Reset history
        check.events.removeAll(keepingCapacity: true)

        for breach in result.breaches {
            let event = BreachEvent(
                breachName: breach.name,
                occurredAt: breach.occurredAt,
                addedAt: breach.addedAt
            )
            event.check = check
            check.events.append(event)
        }

        check.breachCount = result.breaches.count
        check.lastCheckedAt = result.checkedAt
        check.lastResultSummary =
            result.breaches.isEmpty
            ? "No breaches found"
            : "\(result.breaches.count) breach(es) found"
    }
}
