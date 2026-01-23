import Foundation
import SwiftData

@Model
final class BreachCheck {
    //Input
    var emailAddress: String

    //Audit metadata
    var createdAt: Date
    var lastCheckedAt: Date?

    //Dashboard fields
    var breachCount: Int
    var lastResultSummary: String?

    // One check -> many breach events
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
    // Inverse relationship (assigned when appended to BreachCheck.events)
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