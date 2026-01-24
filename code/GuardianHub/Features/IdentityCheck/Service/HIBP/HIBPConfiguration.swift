import Foundation

struct HIBPConfiguration: Sendable {
    let apiKey: String
    let userAgent: String

    init(apiKey: String, userAgent: String = "GuardianHub/1.0 (University Project)") {
        self.apiKey = apiKey
        self.userAgent = userAgent
    }
}
