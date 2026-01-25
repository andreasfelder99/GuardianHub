import Foundation
import SwiftData

@Model
final class WebScan {
    var urlString: String

    var createdAt: Date
    var lastScannedAt: Date?

    var tlsSummary: String
    var isTLSValid: Bool
    var certificateCommonName: String?
    var certificateIssuer: String?
    var certificateValidUntil: Date?

    var headerSummary: String
    var hasHSTS: Bool
    var hasCSP: Bool

    var notes: String?

    init(urlString: String) {
        self.urlString = urlString
        self.createdAt = .now
        self.lastScannedAt = nil

        self.tlsSummary = "Not scanned"
        self.isTLSValid = false
        self.certificateCommonName = nil
        self.certificateIssuer = nil
        self.certificateValidUntil = nil

        self.headerSummary = "Not scanned"
        self.hasHSTS = false
        self.hasCSP = false

        self.notes = nil
    }
}
