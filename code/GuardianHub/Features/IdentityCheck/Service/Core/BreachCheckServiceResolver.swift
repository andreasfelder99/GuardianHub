import Foundation

struct BreachCheckServiceResolution: Sendable {
    let service: any BreachCheckServicing
    let modeInUse: BreachCheckServiceMode
    let reason: String
}

enum BreachCheckServiceResolver {

    static func resolve(
        preferredMode: BreachCheckServiceMode,
        userAgent: String = "GuardianHub/1.0 (University Project)"
    ) -> BreachCheckServiceResolution {

        let key = HIBPAPIKeyStore.load()

        switch preferredMode {
        case .stub:
            return BreachCheckServiceResolution(
                service: StubBreachCheckService(),
                modeInUse: .stub,
                reason: "Mock service selected."
            )

        case .live:
            guard let key else {
                return BreachCheckServiceResolution(
                    service: StubBreachCheckService(),
                    modeInUse: .stub,
                    reason: "No API key configured. Falling back to mock service."
                )
            }
            return BreachCheckServiceResolution(
                service: makeLiveService(apiKey: key, userAgent: userAgent),
                modeInUse: .live,
                reason: "Live service selected."
            )

        case .automatic:
            if let key {
                return BreachCheckServiceResolution(
                    service: makeLiveService(apiKey: key, userAgent: userAgent),
                    modeInUse: .live,
                    reason: "API key found. Using live service."
                )
            } else {
                return BreachCheckServiceResolution(
                    service: StubBreachCheckService(),
                    modeInUse: .stub,
                    reason: "No API key configured. Using mock service."
                )
            }
        }
    }

    private static func makeLiveService(apiKey: String, userAgent: String) -> any BreachCheckServicing {
        return StubBreachCheckService()
    }
}
