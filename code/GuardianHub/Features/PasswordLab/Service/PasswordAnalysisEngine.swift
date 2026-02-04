import Foundation

public struct PasswordAnalysisEngine: Sendable {

    public init() {}

    public func analyze(_ password: String) -> PasswordAnalysisResult {
        let trimmed = password.trimmingCharacters(in: .newlines)
        let length = trimmed.count

        guard length > 0 else {
            return PasswordAnalysisResult(
                passwordLength: 0,
                entropyBits: 0,
                category: .veryWeak,
                meterValue: 0,
                warnings: [
                    PasswordWarning(
                        id: "empty",
                        title: "Enter a password",
                        detail: "Analysis updates as you type. Nothing is stored or sent.",
                        severity: .info
                    )
                ],
                breakdown: [EntropyComponent(label: "Baseline", bits: 0)]
            )
        }

        var warnings: [PasswordWarning] = []
        var breakdown: [EntropyComponent] = []

        // 1) Baseline entropy via effective alphabet size
        let classes = characterClasses(in: trimmed)
        let alphabetSize = effectiveAlphabetSize(for: classes)
        let baselineBits = Double(length) * log2(Double(alphabetSize))
        breakdown.append(.init(label: "Baseline (length × log2(alphabet))", bits: baselineBits))

        // 2) Adjustments (transparent deductions/additions)
        var adjustments: [EntropyComponent] = []

        // Length guidance (no direct deduction; warning only)
        if length < 8 {
            warnings.append(.init(
                id: "too_short_8",
                title: "Too short",
                detail: "Under 8 characters is highly guessable. Aim for 12+.",
                severity: .critical
            ))
        } else if length < 12 {
            warnings.append(.init(
                id: "short_12",
                title: "Consider a longer password",
                detail: "12+ characters significantly increases resistance to guessing.",
                severity: .warning
            ))
        }

        // Low variety
        if classes.count == 1 {
            warnings.append(.init(
                id: "single_class",
                title: "Low character variety",
                detail: "Using only one character type (e.g., only letters or only digits) reduces the search space.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: single character class", bits: -min(12, baselineBits * 0.25)))
        }

        // Repeated characters runs (aaa / 111)
        if hasRepeatedRun(trimmed, runLength: 3) {
            warnings.append(.init(
                id: "repeat_run",
                title: "Repeated characters",
                detail: "Runs like “aaa” or “111” are common patterns and easier to guess.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: repeated character runs", bits: -min(10, baselineBits * 0.15)))
        }

        // Repeated substring (abcabc)
        if let period = smallestRepeatPeriod(trimmed), period < length {
            warnings.append(.init(
                id: "repeat_substring",
                title: "Repeated pattern",
                detail: "Repetition like a short chunk repeated multiple times reduces effective complexity.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: repeated substring pattern", bits: -min(14, baselineBits * 0.20)))
        }

        // Sequential runs (abcd, 1234)
        if let run = findSequentialRun(trimmed, minLength: 4) {
            warnings.append(.init(
                id: "sequential_run",
                title: "Sequential characters",
                detail: "Sequences like “\(run)” are frequently tried by attackers.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: sequential run", bits: -min(12, baselineBits * 0.18)))
        }

        // Keyboard sequences (qwerty, asdf)
        if let seq = findKeyboardSequence(trimmed, minLength: 4) {
            warnings.append(.init(
                id: "keyboard_sequence",
                title: "Keyboard pattern",
                detail: "Keyboard sequences like “\(seq)” are among the most common password choices.",
                severity: .critical
            ))
            adjustments.append(.init(label: "Deduction: keyboard sequence", bits: -min(18, baselineBits * 0.30)))
        }

        // Common password / dictionary (offline list)
        if isCommonPassword(trimmed) {
            warnings.append(.init(
                id: "common_password",
                title: "Common password",
                detail: "This appears in common-password lists. Attackers try these early.",
                severity: .critical
            ))
            // Replace baseline with a small “dictionary space” assumption
            // (transparent: treat as chosen from a short list).
            let dictionaryBits = log2(Double(commonPasswords.count))
            adjustments.append(.init(label: "Deduction: common-password list match", bits: -max(0, baselineBits - dictionaryBits)))
        }

        // Predictable casing (only first letter uppercase)
        if isCapitalizedFirstOnly(trimmed) {
            warnings.append(.init(
                id: "capitalized_first",
                title: "Predictable capitalization",
                detail: "Capitalizing only the first letter is a common transformation and often guessed.",
                severity: .info
            ))
            adjustments.append(.init(label: "Deduction: predictable capitalization", bits: -min(6, baselineBits * 0.08)))
        }

        // Common suffix patterns: trailing digits, year, or "!"
        if let suffix = commonSuffixPattern(trimmed) {
            warnings.append(.init(
                id: "common_suffix",
                title: "Common suffix pattern",
                detail: "Suffixes like “\(suffix)” are common and often targeted by rule-based guesses.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: common suffix pattern", bits: -min(10, baselineBits * 0.12)))
        }

        // Apply adjustments
        for a in adjustments { breakdown.append(a) }
        let finalBits = max(0, baselineBits + adjustments.reduce(0) { $0 + $1.bits })

        let category = category(forEntropyBits: finalBits)
        let meter = meterValue(forEntropyBits: finalBits)

        return PasswordAnalysisResult(
            passwordLength: length,
            entropyBits: finalBits,
            category: category,
            meterValue: meter,
            warnings: normalizedWarnings(warnings),
            breakdown: breakdown
        )
    }
}

// MARK: - Rules / Helpers

private struct CharacterClass: Hashable {
    let name: String
}

private func characterClasses(in password: String) -> Set<CharacterClass> {
    var classes: Set<CharacterClass> = []

    for scalar in password.unicodeScalars {
        switch scalar.value {
        case 65...90: classes.insert(.init(name: "upper"))   // A-Z
        case 97...122: classes.insert(.init(name: "lower"))  // a-z
        case 48...57: classes.insert(.init(name: "digit"))   // 0-9
        default:
            // treat everything else as "symbol" (includes punctuation, whitespace, unicode)
            classes.insert(.init(name: "symbol"))
        }
    }

    return classes
}

private func effectiveAlphabetSize(for classes: Set<CharacterClass>) -> Int {
    // Transparent, simple model.
    // Note: symbol count is approximate for printable ASCII punctuation.
    var size = 0
    if classes.contains(.init(name: "lower")) { size += 26 }
    if classes.contains(.init(name: "upper")) { size += 26 }
    if classes.contains(.init(name: "digit")) { size += 10 }
    if classes.contains(.init(name: "symbol")) { size += 33 }
    return max(1, size)
}

private func category(forEntropyBits bits: Double) -> PasswordStrengthCategory {
    switch bits {
    case ..<28: return .veryWeak
    case ..<36: return .weak
    case ..<60: return .fair
    default: return .strong
    }
}

private func meterValue(forEntropyBits bits: Double) -> Double {
    // Normalize to 0...1 with a soft cap at 80 bits for UI meter.
    let capped = min(80, max(0, bits))
    return capped / 80.0
}

private func hasRepeatedRun(_ s: String, runLength: Int) -> Bool {
    guard runLength >= 2 else { return false }
    var last: Character?
    var currentRun = 0

    for ch in s {
        if ch == last {
            currentRun += 1
            if currentRun >= runLength { return true }
        } else {
            last = ch
            currentRun = 1
        }
    }
    return false
}

private func smallestRepeatPeriod(_ s: String) -> Int? {
    // If s is composed of repetition of a substring, return that substring length (period).
    // Example: "abcabc" -> 3
    let chars = Array(s)
    let n = chars.count
    guard n >= 4 else { return nil }

    for p in 1...(n / 2) where n % p == 0 {
        var matches = true
        for i in 0..<n {
            if chars[i] != chars[i % p] {
                matches = false
                break
            }
        }
        if matches { return p }
    }
    return nil
}

private func findSequentialRun(_ s: String, minLength: Int) -> String? {
    let lowered = s.lowercased()
    let chars = Array(lowered)
    guard chars.count >= minLength else { return nil }

    func isSeq(_ a: Character, _ b: Character) -> Bool {
        guard let av = a.asciiValue, let bv = b.asciiValue else { return false }
        return bv == av + 1
    }

    var start = 0
    for i in 1..<chars.count {
        if isSeq(chars[i - 1], chars[i]) {
            // continue
        } else {
            let len = i - start
            if len >= minLength {
                return String(chars[start..<i])
            }
            start = i
        }
    }

    let finalLen = chars.count - start
    if finalLen >= minLength {
        return String(chars[start..<chars.count])
    }
    return nil
}

private let keyboardSequences: [String] = [
    "qwertyuiop",
    "asdfghjkl",
    "zxcvbnm",
    "1234567890"
]

private func findKeyboardSequence(_ s: String, minLength: Int) -> String? {
    let lowered = s.lowercased()
    for seq in keyboardSequences {
        if let match = longestContainedSubstring(of: lowered, in: seq, minLength: minLength) {
            return match
        }
        // also check reverse (e.g. "poiuy")
        let reversed = String(seq.reversed())
        if let match = longestContainedSubstring(of: lowered, in: reversed, minLength: minLength) {
            return match
        }
    }
    return nil
}

private func longestContainedSubstring(of s: String, in sequence: String, minLength: Int) -> String? {
    // find any substring of `sequence` with length >= minLength that appears in `s`
    let seqChars = Array(sequence)
    guard seqChars.count >= minLength else { return nil }

    // Prefer longer matches (more meaningful warning)
    for len in stride(from: seqChars.count, through: minLength, by: -1) {
        for start in 0...(seqChars.count - len) {
            let sub = String(seqChars[start..<(start + len)])
            if s.contains(sub) {
                return sub
            }
        }
    }
    return nil
}

// Minimal offline common-password list (expandable).
// This is intentionally small to keep the repo clean; you can extend later
// or ship a local wordlist file if desired.
private let commonPasswords: Set<String> = [
    "password", "passw0rd", "123456", "12345678", "123456789", "qwerty",
    "letmein", "admin", "welcome", "iloveyou", "monkey", "dragon",
    "football", "secret", "login", "princess", "sunshine"
]

private func isCommonPassword(_ s: String) -> Bool {
    let lowered = s.lowercased()
    if commonPasswords.contains(lowered) { return true }

    // also catch trivial digit-only patterns like 000000, 111111
    if lowered.allSatisfy({ $0.isNumber }) {
        let unique = Set(lowered)
        if unique.count == 1 { return true }
    }
    return false
}

private func isCapitalizedFirstOnly(_ s: String) -> Bool {
    guard s.count >= 2 else { return false }
    let chars = Array(s)
    guard let first = chars.first else { return false }
    guard String(first).rangeOfCharacter(from: .uppercaseLetters) != nil else { return false }

    let rest = String(chars.dropFirst())
    // rest all lowercase letters (or non-letters)
    let letters = rest.filter { $0.isLetter }
    return !letters.isEmpty && letters.allSatisfy { String($0).rangeOfCharacter(from: .lowercaseLetters) != nil }
}

private func commonSuffixPattern(_ s: String) -> String? {
    let lowered = s.lowercased()

    // Trailing "!" (very common)
    if lowered.hasSuffix("!") { return "!" }

    // Trailing 1-4 digits
    if let m = lowered.range(of: #"\d{1,4}$"#, options: .regularExpression) {
        return String(lowered[m])
    }

    // Year 1900-2099
    if let m = lowered.range(of: #"(19|20)\d{2}$"#, options: .regularExpression) {
        return String(lowered[m])
    }

    return nil
}

private func normalizedWarnings(_ warnings: [PasswordWarning]) -> [PasswordWarning] {
    // De-duplicate by id, preserve first occurrence order.
    var seen: Set<String> = []
    var out: [PasswordWarning] = []
    for w in warnings {
        guard !seen.contains(w.id) else { continue }
        seen.insert(w.id)
        out.append(w)
    }
    return out
}
