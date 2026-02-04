import Foundation

public struct PasswordAnalysisEngine: Sendable {

    public init() {}

    public func analyze(_ password: String) -> PasswordAnalysisResult {
        let input = password.trimmingCharacters(in: .newlines)
        let length = input.count

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

        // 1) Baseline entropy using effective alphabet size
        let classes = characterClasses(in: input)
        let alphabetSize = effectiveAlphabetSize(for: classes)
        let baselineBits = Double(length) * log2(Double(alphabetSize))
        breakdown.append(.init(label: "Baseline (length × log2(alphabet))", bits: baselineBits))

        // 2) Transparent adjustments (deductions)
        var adjustments: [EntropyComponent] = []

        // Length guidance (warning-only)
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

        // Single character class
        if classes.count == 1 {
            warnings.append(.init(
                id: "single_class",
                title: "Low character variety",
                detail: "Using only one character type reduces the search space (e.g., only digits).",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: single character class", bits: -min(12, baselineBits * 0.25)))
        }

        // Repeated character runs
        if hasRepeatedRun(input, runLength: 3) {
            warnings.append(.init(
                id: "repeat_run",
                title: "Repeated characters",
                detail: "Runs like “aaa” or “111” are common patterns and easier to guess.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: repeated character runs", bits: -min(10, baselineBits * 0.15)))
        }

        // Repeated substring
        if let period = smallestRepeatPeriod(input), period < length {
            warnings.append(.init(
                id: "repeat_substring",
                title: "Repeated pattern",
                detail: "Repeating a short chunk reduces effective complexity.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: repeated substring pattern", bits: -min(14, baselineBits * 0.20)))
        }

        // Sequential runs (abcd, 1234)
        if let run = findSequentialRun(input, minLength: 4) {
            warnings.append(.init(
                id: "sequential_run",
                title: "Sequential characters",
                detail: "Sequences like “\(run)” are frequently tried by attackers.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: sequential run", bits: -min(12, baselineBits * 0.18)))
        }

        // Keyboard sequences (qwerty / asdf / zxcv / 1234)
        if let seq = findKeyboardSequence(input, minLength: 4) {
            warnings.append(.init(
                id: "keyboard_sequence",
                title: "Keyboard pattern",
                detail: "Keyboard sequences like “\(seq)” are among the most common choices.",
                severity: .critical
            ))
            adjustments.append(.init(label: "Deduction: keyboard sequence", bits: -min(18, baselineBits * 0.30)))
        }

        // Common suffix patterns (digits / year / !)
        let suffix = commonSuffixPattern(input)
        if let suffix {
            warnings.append(.init(
                id: "common_suffix",
                title: "Common suffix pattern",
                detail: "Suffixes like “\(suffix)” are commonly targeted by rule-based guesses.",
                severity: .warning
            ))
            adjustments.append(.init(label: "Deduction: common suffix pattern", bits: -min(10, baselineBits * 0.12)))
        }

        // Common password list (offline)
        if isCommonPassword(input) {
            warnings.append(.init(
                id: "common_password",
                title: "Common password",
                detail: "This matches common-password lists. Attackers try these early.",
                severity: .critical
            ))
            let dictionaryBits = log2(Double(commonPasswords.count))
            adjustments.append(.init(label: "Deduction: common-password list match", bits: -max(0, baselineBits - dictionaryBits)))
        }

        // Predictable capitalization
        if isCapitalizedFirstOnly(input) {
            warnings.append(.init(
                id: "capitalized_first",
                title: "Predictable capitalization",
                detail: "Capitalizing only the first letter is a common transformation.",
                severity: .info
            ))
            adjustments.append(.init(label: "Deduction: predictable capitalization", bits: -min(6, baselineBits * 0.08)))
        }

        // 3) Dictionary-word segmentation (FIXED)
        // Apply wordlist-based entropy for 1+ detected word(s) when mostly letters
        // (optionally with a numeric suffix). This prevents single dictionary words
        // from being overrated by the character-randomness baseline.
        let (wordSet, wordCount) = PasswordWordlistStore.shared.loadWords()
        if wordCount > 0 {
            let lowered = input.lowercased()
            let lettersPrefix = lowered.prefix { $0.isLetter }
            let digitsSuffix = lowered.dropFirst(lettersPrefix.count)

            // Only attempt segmentation when we have a meaningful letters part
            if lettersPrefix.count >= 4, (digitsSuffix.isEmpty || digitsSuffix.allSatisfy(\.isNumber)) {
                if let segmentation = segmentIntoWords(String(lettersPrefix), words: wordSet, maxWords: 4),
                   segmentation.words.count >= 1 {

                    let k = segmentation.words.count
                    let bitsWords = Double(k) * log2(Double(wordCount))
                    let suffixBits = estimateSuffixBits(String(digitsSuffix))
                    let passphraseBits = bitsWords + suffixBits
                    let delta = passphraseBits - baselineBits

                    if k == 1 {
                        warnings.append(.init(
                            id: "dictionary_word_single",
                            title: "Single dictionary word",
                            detail: "Single common words are often targeted early by wordlist attacks. Consider multiple unrelated words.",
                            severity: .warning
                        ))
                    } else {
                        warnings.append(.init(
                            id: "dictionary_words",
                            title: "Dictionary words detected",
                            detail: "This looks like combined common words (e.g., “\(segmentation.words.joined(separator: " + "))”). Wordlist attacks can guess these faster than random strings.",
                            severity: .critical
                        ))
                    }

                    adjustments.append(.init(
                        label: "Adjustment: wordlist estimate (\(k) word\(k == 1 ? "" : "s") from ~\(wordCount))",
                        bits: delta
                    ))
                }
            }
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

// MARK: - Dictionary segmentation

private struct SegmentationResult: Sendable {
    let words: [String]
}

/// DP-based segmentation into up to `maxWords` words from the set.
/// Returns the segmentation using the fewest words.
private func segmentIntoWords(_ s: String, words: Set<String>, maxWords: Int) -> SegmentationResult? {
    let chars = Array(s)
    let n = chars.count
    guard n > 0 else { return nil }

    var dp: [SegmentationResult?] = Array(repeating: nil, count: n + 1)
    dp[0] = SegmentationResult(words: [])

    let minLen = 3
    let maxLen = 20

    for i in 0..<n {
        guard let current = dp[i] else { continue }
        if current.words.count >= maxWords { continue }

        let remaining = n - i
        let upper = min(maxLen, remaining)

        if upper >= minLen {
            for len in stride(from: upper, through: minLen, by: -1) {
                let candidate = String(chars[i..<(i + len)])
                if words.contains(candidate) {
                    var newWords = current.words
                    newWords.append(candidate)

                    let next = i + len
                    let proposal = SegmentationResult(words: newWords)

                    if dp[next] == nil || proposal.words.count < (dp[next]?.words.count ?? .max) {
                        dp[next] = proposal
                    }
                }
            }
        }
    }

    return dp[n]
}

private func estimateSuffixBits(_ suffix: String) -> Double {
    guard !suffix.isEmpty else { return 0 }

    let trivial: Set<String> = [
        "1", "12", "123", "1234", "12345",
        "0", "00", "000", "0000",
        "11", "111", "1111",
        "22", "222", "2222",
        "99", "999", "9999"
    ]
    if trivial.contains(suffix) { return 0.5 }

    if suffix.count == 4, let year = Int(suffix), (1900...2099).contains(year) {
        return log2(200)
    }

    let len = suffix.count
    let space = pow(10.0, Double(len))
    return min(20, log2(space))
}

// MARK: - Helpers (pure, deterministic)

private struct CharacterClass: Hashable { let name: String }

private func characterClasses(in password: String) -> Set<CharacterClass> {
    var classes: Set<CharacterClass> = []
    for scalar in password.unicodeScalars {
        switch scalar.value {
        case 65...90: classes.insert(.init(name: "upper"))
        case 97...122: classes.insert(.init(name: "lower"))
        case 48...57: classes.insert(.init(name: "digit"))
        default: classes.insert(.init(name: "symbol"))
        }
    }
    return classes
}

private func effectiveAlphabetSize(for classes: Set<CharacterClass>) -> Int {
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
    let capped = min(80, max(0, bits))
    return capped / 80.0
}

private func hasRepeatedRun(_ s: String, runLength: Int) -> Bool {
    guard runLength >= 2 else { return false }
    var last: Character?
    var run = 0
    for ch in s {
        if ch == last {
            run += 1
            if run >= runLength { return true }
        } else {
            last = ch
            run = 1
        }
    }
    return false
}

private func smallestRepeatPeriod(_ s: String) -> Int? {
    let chars = Array(s)
    let n = chars.count
    guard n >= 4 else { return nil }
    for p in 1...(n / 2) where n % p == 0 {
        var ok = true
        for i in 0..<n where chars[i] != chars[i % p] { ok = false; break }
        if ok { return p }
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
            continue
        } else {
            let len = i - start
            if len >= minLength { return String(chars[start..<i]) }
            start = i
        }
    }

    let finalLen = chars.count - start
    if finalLen >= minLength { return String(chars[start..<chars.count]) }
    return nil
}

private let keyboardSequences: [String] = ["qwertyuiop", "asdfghjkl", "zxcvbnm", "1234567890"]

private func findKeyboardSequence(_ s: String, minLength: Int) -> String? {
    let lowered = s.lowercased()
    for seq in keyboardSequences {
        if let match = longestContainedSubstring(of: lowered, in: seq, minLength: minLength) { return match }
        let reversed = String(seq.reversed())
        if let match = longestContainedSubstring(of: lowered, in: reversed, minLength: minLength) { return match }
    }
    return nil
}

private func longestContainedSubstring(of s: String, in sequence: String, minLength: Int) -> String? {
    let seqChars = Array(sequence)
    guard seqChars.count >= minLength else { return nil }
    for len in stride(from: seqChars.count, through: minLength, by: -1) {
        for start in 0...(seqChars.count - len) {
            let sub = String(seqChars[start..<(start + len)])
            if s.contains(sub) { return sub }
        }
    }
    return nil
}

private let commonPasswords: Set<String> = [
    "password", "passw0rd", "123456", "12345678", "123456789", "qwerty",
    "letmein", "admin", "welcome", "iloveyou", "monkey", "dragon",
    "football", "secret", "login", "princess", "sunshine"
]

private func isCommonPassword(_ s: String) -> Bool {
    let lowered = s.lowercased()
    if commonPasswords.contains(lowered) { return true }
    if lowered.allSatisfy(\.isNumber) {
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
    let letters = rest.filter(\.isLetter)
    return !letters.isEmpty && letters.allSatisfy { String($0).rangeOfCharacter(from: .lowercaseLetters) != nil }
}

private func commonSuffixPattern(_ s: String) -> String? {
    let lowered = s.lowercased()
    if lowered.hasSuffix("!") { return "!" }
    if let r = lowered.range(of: #"\d{1,4}$"#, options: .regularExpression) { return String(lowered[r]) }
    if let r = lowered.range(of: #"(19|20)\d{2}$"#, options: .regularExpression) { return String(lowered[r]) }
    return nil
}

private func normalizedWarnings(_ warnings: [PasswordWarning]) -> [PasswordWarning] {
    var seen: Set<String> = []
    var out: [PasswordWarning] = []
    for w in warnings where !seen.contains(w.id) {
        seen.insert(w.id)
        out.append(w)
    }
    return out
}
