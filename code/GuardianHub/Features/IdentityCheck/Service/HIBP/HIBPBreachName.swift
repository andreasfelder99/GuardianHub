import Foundation

struct HIBPBreachName: Decodable, Sendable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}
