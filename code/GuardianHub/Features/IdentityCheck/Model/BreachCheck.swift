import Foundation
import SwiftData

@Model
final class BreachCheck {
    // the email we're tracking
    var emailAddress: String

    // when was this check created / last time we checked HIBP
    var createdAt: Date
    var lastCheckedAt: Date?

    // quick summary for dashboard - don't need to query all events every time
    var breachCount: Int
    var lastResultSummary: String?

    // one check can have many breach events (cascade delete so if we delete the check, events go too)
    @Relationship(deleteRule: .cascade, inverse: \BreachEvent.check)
    var events: [BreachEvent]

    init(emailAddress: String) {
        self.emailAddress = emailAddress
        self.createdAt = .now
        self.lastCheckedAt = nil
        self.breachCount = 0
        self.lastResultSummary = nil
        self.events = []
    }

}

@Model
final class BreachEvent {
    // back reference to the check (SwiftData handles this when we append to events array)
    var check: BreachCheck?

    // Minimal fields now; we can extend with HIBP fields later (Domain, DataClasses, etc.)
    var breachName: String
    var occurredAt: Date?
    var addedAt: Date?

    init(breachName: String, occurredAt: Date? = nil, addedAt: Date? = nil) {
        self.check = nil
        self.breachName = breachName
        self.occurredAt = occurredAt
        self.addedAt = addedAt
    }
}