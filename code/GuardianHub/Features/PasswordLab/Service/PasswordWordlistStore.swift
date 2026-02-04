import Foundation

/// Loads a newline-separated word list from the app bundle.
/// - Fully offline
/// - Cached in-memory after first load
/// - Lowercased words only
struct PasswordWordlistStore: Sendable {

    static let shared = PasswordWordlistStore()

    private let resourceName = "CommonWords_en"
    private let resourceExtension = "txt"

    private init() {}

    /// Returns the word set and its size. If the resource isn't present, returns an empty set.
    func loadWords() -> (words: Set<String>, count: Int) {
        // Cache via static once-token pattern.
        Cached.wordsAndCount
    }

    // MARK: - Cache

    private enum Cached {
        static let wordsAndCount: (words: Set<String>, count: Int) = {
            guard let url = Bundle.main.url(forResource: PasswordWordlistStore.shared.resourceName,
                                            withExtension: PasswordWordlistStore.shared.resourceExtension)
            else {
                // Resource not included in target or renamed.
                return ([], 0)
            }

            do {
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else {
                    return ([], 0)
                }

                // One word per line. Normalize to lowercase, letters only.
                var set = Set<String>()
                set.reserveCapacity(12_000)

                text.enumerateLines { line, _ in
                    let w = line
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()

                    guard !w.isEmpty else { return }
                    // Keep words reasonably clean (avoid weird tokens)
                    guard w.allSatisfy({ $0.isLetter }) else { return }
                    set.insert(w)
                }

                return (set, set.count)
            } catch {
                return ([], 0)
            }
        }()
    }
}
