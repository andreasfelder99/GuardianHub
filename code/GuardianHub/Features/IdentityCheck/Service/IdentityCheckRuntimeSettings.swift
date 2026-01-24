import Observation

@Observable
final class IdentityCheckRuntimeSettings {
    var preferredMode: BreachCheckServiceMode = .automatic
    var lastResolutionMessage: String? = nil
}
