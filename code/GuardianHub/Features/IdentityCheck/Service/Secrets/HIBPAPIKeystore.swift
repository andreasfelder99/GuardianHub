import Foundation

enum HIBPAPIKeyStore {
    private static let account = "hibp_api_key"

    private static var service: String {
        Bundle.main.bundleIdentifier ?? "GuardianHub"
    }

    static func load() -> String? {
        do {
            return try KeychainStore.read(service: service, account: account)
        } catch {
            // In production you might log this; for now fail closed.
            return nil
        }
    }

    static func save(_ apiKey: String) -> Bool {
        do {
            try KeychainStore.write(apiKey, service: service, account: account)
            return true
        } catch {
            return false
        }
    }

    static func remove() -> Bool {
        do {
            try KeychainStore.delete(service: service, account: account)
            return true
        } catch {
            return false
        }
    }
}
