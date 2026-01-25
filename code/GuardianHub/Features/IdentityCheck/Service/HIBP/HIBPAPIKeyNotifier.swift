import Foundation
import Observation

@Observable
final class HIBPAPIKeyNotifier {
    var revision: Int = 0

    func bump() {
        revision &+= 1
    }
}
