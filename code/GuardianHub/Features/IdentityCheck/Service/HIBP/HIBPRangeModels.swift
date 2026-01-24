import Foundation

// Response element from the breached account range API.
struct HIBPBreachedAccountRangeItem: Decodable, Sendable {
    let hashSuffix: String
    let websites: [String]

    enum CodingKeys: String, CodingKey {
        case hashSuffix = "HashSuffix"
        case websites = "Websites"
    }
}
