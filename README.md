# GuardianHub

> **A comprehensive iOS & macOS security suite built with SwiftUI, demonstrating modern Apple platform development best practices.**

GuardianHub is a native multi-platform security application that provides users with tools for identity protection, web security auditing, photo privacy management, and password strength analysis. The application prioritizes privacy-by-design principles, running sensitive analyses locally without transmitting user data to external servers.

---

## Table of Contents

- [Features Overview](#features-overview)
- [Use Cases & I/O Requirements](#use-cases--io-requirements)
- [Architecture](#architecture)
  - [Modular Feature-Based Architecture](#modular-feature-based-architecture)
  - [Navigation Architecture](#navigation-architecture)
  - [Data Persistence with SwiftData](#data-persistence-with-swiftdata)
- [Technical Highlights](#technical-highlights)
  - [On-Device AI Integration (Apple Intelligence)](#on-device-ai-integration-apple-intelligence)
  - [Advanced Password Entropy Analysis](#advanced-password-entropy-analysis)
  - [TLS Certificate Chain Validation](#tls-certificate-chain-validation)
  - [EXIF Metadata Stripping Engine](#exif-metadata-stripping-engine)
  - [Protocol-Oriented Service Layer](#protocol-oriented-service-layer)
- [Design System](#design-system)
- [Best Practices Demonstrated](#best-practices-demonstrated)
- [Platform Adaptations](#platform-adaptations)
- [Privacy & Security Considerations](#privacy--security-considerations)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Building & Running](#building--running)

---

## Features Overview

### 1. Identity Check
Monitor email addresses for data breaches using the Have I Been Pwned (HIBP) API.
- Real-time breach detection with API integration
- Secure API key storage via iOS/macOS Keychain
- Mock service mode for development and demonstrations
- Rate limit handling with automatic retry scheduling

### 2. Web Auditor
Comprehensive website security analysis with TLS and HTTP security header auditing.
- **TLS Certificate Validation**: Full certificate chain evaluation using `SecTrust`
- **Security Headers Analysis**: Detection of HSTS, CSP, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, and Permissions-Policy
- **AI-Powered Explanations**: On-device Foundation Models integration for natural language security explanations

### 3. Privacy Guard
Photo metadata inspection and sanitization for privacy protection.
- EXIF/TIFF/GPS metadata extraction using ImageIO
- Interactive map visualization of geotagged photos
- Metadata stripping with full resolution preservation
- Batch processing with platform-specific export workflows

### 4. Password Lab
Sophisticated password strength analyzer with transparent entropy calculations.
- **Information-theoretic entropy estimation**
- **Dynamic programming wordlist segmentation**
- **Pattern detection**: keyboard sequences, repeated characters, common suffixes
- **Crack time estimation** for online and offline attack scenarios
- **Haptic feedback** for password strength transitions (iOS)

---

## Use Cases & I/O Requirements

This project implements four distinct use cases, each demonstrating different I/O patterns and Apple platform capabilities:

### Use Case 1: "Am I affected by data breaches?" (Identity Check)

**Problem Statement:** Users want to know if their email addresses have been exposed in known data breaches.

**I/O Implementation:**
| Requirement | Implementation |
|-------------|----------------|
| **Web API Integration** | `HIBPBreachedAccountClient` communicates with Have I Been Pwned API v3 via `URLSession` |
| **Data Persistence** | `BreachCheck` and `BreachEvent` SwiftData models with `@Relationship(deleteRule: .cascade)` |
| **Secure Storage** | API key stored in iOS/macOS Keychain via `SecItemAdd`/`SecItemCopyMatching` |

**Technical Details:**
- RESTful API calls with proper HTTP headers (`hibp-api-key`, `user-agent`)
- Rate limit handling with `Retry-After` header parsing and automatic countdown
- Service resolver pattern enabling mock/live mode switching for development
- SwiftData `@Query` macro for reactive UI updates when breach data changes

```swift
// API Integration
let (data, response) = try await session.data(for: request)
if http.statusCode == 429 {
    let retryAfter = Self.parseRetryAfterSeconds(from: http)
    throw HIBPError.rateLimited(retryAfterSeconds: retryAfter)
}
```

---

### Use Case 2: "Can I trust this website?" (Web Auditor)

**Problem Statement:** Users want to verify the technical security of websites before entering sensitive data.

**I/O Implementation:**
| Requirement | Implementation |
|-------------|----------------|
| **TLS Certificate Validation** | `URLSessionDelegate` with `SecTrustEvaluateWithError` for **cryptographic** chain validation |
| **Security Header Analysis** | HTTP response header parsing for HSTS, CSP, X-Frame-Options, etc. |
| **Complex Networking** | Custom `URLSessionDelegate` to intercept TLS handshake and extract certificate chain |
| **AI Explanations** | On-device FoundationModels for natural language security summaries |

**Cryptographic TLS Validation:**

The TLS auditor performs **actual cryptographic validation** of the certificate chain, not superficial inspection:

```swift
// SecTrustEvaluateWithError performs FULL cryptographic validation:
// 1. Verifies digital signatures on each certificate in the chain
// 2. Validates certificate chain from leaf → intermediate → root CA
// 3. Checks certificate validity periods (notBefore/notAfter)
// 4. Verifies the root certificate is in the system trust store
// 5. Checks for certificate revocation (OCSP/CRL when available)
// 6. Validates hostname matches certificate's CN or SAN fields

var error: CFError?
let trusted = SecTrustEvaluateWithError(trust, &error)  // Returns false if ANY check fails
```

**Certificate Chain Extraction (macOS):**
```swift
// Extract issuer using X.509 OID-based parsing
let keys: [CFString] = [kSecOIDX509V1IssuerName]  // OID 2.5.4.3 (CN), 2.5.4.10 (O)
let values = SecCertificateCopyValues(cert, keys as CFArray, nil)
// Parse CN and Organization from ASN.1 DER-encoded issuer field
```

**Parallel Audit Execution:**
```swift
async let headerResult = headerAuditor.audit(url: url)  // Security headers
async let tlsResult = tlsAuditor.audit(url: url)        // Certificate chain
let (headers, tls) = try await (headerResult, tlsResult) // Concurrent execution
```

---

### Use Case 3: "Do my photos reveal my location?" (Privacy Guard)

**Problem Statement:** Photos often contain hidden GPS coordinates and camera metadata that can compromise privacy when shared.

**I/O Implementation:**
| Requirement | Implementation |
|-------------|----------------|
| **File I/O** | ImageIO framework (`CGImageSource`) for EXIF/TIFF/GPS dictionary extraction |
| **Map Visualization** | MapKit integration with `MKCoordinateRegion` for interactive location display |
| **Metadata Stripping** | `CGImageDestination` re-encoding without metadata dictionaries |
| **Photos Library** | `PHImageManager` for iOS photo access, file bookmarks for macOS |

**EXIF Extraction Pipeline:**
```swift
let source = CGImageSourceCreateWithData(data as CFData, nil)
let raw = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]

let tiff = raw[kCGImagePropertyTIFFDictionary]  // Camera make/model
let exif = raw[kCGImagePropertyExifDictionary]  // Exposure, aperture, etc.
let gps = raw[kCGImagePropertyGPSDictionary]    // Latitude, longitude, altitude
```

**Interactive Map Preview:**
```swift
Map(position: $position) {
    Marker("Photo Location", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
}
```

**Lossless Metadata Stripping:**
```swift
// Re-encode at full resolution with orientation baked in, but WITHOUT metadata
CGImageDestinationAddImage(dest, cgImage, nil)  // nil = strip all metadata
```

**Platform-Specific Export:**
- **iOS**: Share Sheet via `UIActivityViewController` with temporary stripped files
- **macOS**: Folder picker (`NSOpenPanel`) with Finder reveal (`NSWorkspace.shared.activateFileViewerSelecting`)

---

### Use Case 4: "How secure is my new password?" (Password Lab)

**Problem Statement:** Users need real-time, mathematically grounded feedback on password strength—not just "must be 8 characters."

**I/O Implementation:**
| Requirement | Implementation |
|-------------|----------------|
| **Real-time UI** | `@Observable` model with instant entropy recalculation on each keystroke |
| **Haptic Feedback** | CoreHaptics `CHHapticEngine` with intensity/sharpness mapped to strength category |
| **Visual Feedback** | Swift Charts for entropy breakdown visualization |
| **Offline Wordlist** | 10,000-word dictionary loaded from bundle for passphrase detection |

**Entropy Calculation with Transparent Breakdown:**
```swift
// Baseline: Shannon entropy approximation
let baselineBits = Double(length) * log2(Double(alphabetSize))

// Deductions for detected patterns (shown in UI)
adjustments.append(.init(label: "Deduction: keyboard sequence", bits: -18))
adjustments.append(.init(label: "Deduction: dictionary word", bits: delta))

// Final entropy shown with full breakdown chart
```

**Haptic Feedback on Strength Transitions:**
```swift
// CoreHaptics (not UIKit) for fine-grained control
let params = [
    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),  // Stronger for "Strong"
    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
]
let event = CHHapticEvent(eventType: .hapticTransient, parameters: params, relativeTime: 0)
try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: [])).start(atTime: 0)
```

**Crack Time Estimation:**
```swift
// Two realistic attack scenarios
let online = Estimate(guessesPerSecond: 100)           // Rate-limited web login
let offline = Estimate(guessesPerSecond: 1_000_000_000) // GPU hash cracking

let expectedTime = 0.5 * pow(2.0, entropyBits) / guessesPerSecond
```

**Privacy Guarantee:** The password **never leaves memory**—no persistence, no logging, no network transmission.

---

## Architecture

### Modular Feature-Based Architecture

The application follows a **feature-based modular architecture**, organizing code by domain rather than layer type. Each feature is self-contained with its own:

```
Features/
├── FeatureName/
│   ├── Model/           # Domain models, SwiftData entities
│   ├── View/            # SwiftUI views
│   ├── Service/         # Business logic, API clients
│   └── Resources/       # Feature-specific assets
```

This structure enables:
- **High cohesion**: Related code stays together
- **Low coupling**: Features are independent and testable in isolation
- **Scalability**: New features can be added without modifying existing code
- **Parallel development**: Teams can work on features independently

### Navigation Architecture

The navigation system implements an **adaptive multi-platform navigation pattern**:

```swift
struct RootNavigationView: View {
    var body: some View {
        #if os(macOS)
        SidebarSplitView()
        #else
        AdaptiveNavigationHost()  // Switches between tab (iPhone) and sidebar (iPad)
        #endif
    }
}
```

Key architectural decisions:
- **`@Observable` Navigation Model**: Centralized navigation state using Swift's modern observation framework
- **Platform-Adaptive UI**: Automatic layout switching based on `horizontalSizeClass`
- **Type-Safe Navigation**: Enum-based section definitions with compile-time safety

```swift
enum AppSection: String, CaseIterable, Identifiable {
    case dashboard, identityCheck, webAuditor, privacyGuard, passwordLab
    
    var themeColor: GuardianTheme.SectionColor { ... }
    var gradient: LinearGradient { ... }
}
```

### Data Persistence with SwiftData

The application leverages **SwiftData** for modern, type-safe persistence:

```swift
@Model
final class BreachCheck {
    var emailAddress: String
    var createdAt: Date
    var breachCount: Int
    
    @Relationship(deleteRule: .cascade, inverse: \BreachEvent.check)
    var events: [BreachEvent]
}
```

Key patterns:
- **Cascade delete rules** for maintaining referential integrity
- **Computed properties** for derived data (avoiding redundant storage)
- **Inverse relationships** for bidirectional navigation
- **`@Query` macro** for reactive, declarative data fetching in views

---

## Technical Highlights

### On-Device AI Integration (Apple Intelligence)

The Web Auditor features **Apple Intelligence integration** using the FoundationModels framework for on-device AI explanations:

```swift
struct FoundationModelsWebAuditExplainer: WebAuditExplanationBuilding {
    func explain(snapshot: WebAuditScanSnapshot) async -> WebAuditExplanation {
        switch SystemLanguageModel.default.availability {
        case .available:
            let session = LanguageModelSession(instructions: securityInstructions)
            return try await session.respond(to: prompt, generating: WebAuditExplanation.self)
        case .unavailable:
            return await fallback.explain(snapshot: snapshot)
        }
    }
}
```

**Key features:**
- **`@Generable` macro** for type-safe AI output generation
- **Graceful degradation** to rule-based explanations when AI is unavailable
- **Structured output** with `RiskLevel` enum and typed response fields
- **Privacy-preserving**: All processing happens on-device

### Advanced Password Entropy Analysis

The Password Lab implements a **transparent, information-theoretic entropy calculation system**:

```swift
public struct PasswordAnalysisEngine: Sendable {
    public func analyze(_ password: String) -> PasswordAnalysisResult {
        // 1. Baseline entropy: length × log₂(effective alphabet)
        let baselineBits = Double(length) * log2(Double(alphabetSize))
        
        // 2. Pattern-based deductions
        var adjustments: [EntropyComponent] = []
        
        // Dynamic programming for wordlist segmentation
        if let segmentation = segmentIntoWords(lettersPrefix, words: wordSet, maxWords: 4) {
            let wordlistBits = Double(k) * log2(Double(wordCount))
            adjustments.append(.init(label: "Wordlist adjustment", bits: wordlistBits - baselineBits))
        }
        
        // 3. Final entropy = max(0, baseline + adjustments)
        return PasswordAnalysisResult(entropyBits: finalBits, breakdown: breakdown)
    }
}
```

**Pattern Detection Algorithms:**
- **DP-based word segmentation**: Optimal decomposition into dictionary words using dynamic programming
- **Keyboard sequence detection**: Identifies QWERTY patterns (forward and reverse)
- **Repeated substring detection**: Uses period-finding algorithm for pattern repetition
- **Sequential character runs**: Detects alphabetic/numeric sequences

**Crack Time Estimation:**
```swift
struct PasswordCrackTimeEstimator: Sendable {
    static let online = Scenario(guessesPerSecond: 100)           // Rate-limited
    static let offlineModerate = Scenario(guessesPerSecond: 1e9)  // Fast hash
    
    func estimate(entropyBits: Double, scenario: Scenario) -> Estimate {
        let space = pow(2.0, entropyBits)
        return Estimate(
            expectedSeconds: 0.5 * space / scenario.guessesPerSecond,
            worstSeconds: 1.0 * space / scenario.guessesPerSecond
        )
    }
}
```

### TLS Certificate Chain Validation

The Web Auditor performs **real cryptographic TLS validation**—not superficial string matching—using Apple's Security framework. The `SecTrustEvaluateWithError` function executes the complete X.509 certificate validation algorithm:

**What `SecTrustEvaluateWithError` Actually Validates:**
1. **Digital Signature Verification**: Cryptographically verifies RSA/ECDSA signatures on each certificate
2. **Chain Building**: Constructs and validates the path from leaf certificate → intermediates → trusted root CA
3. **Validity Period**: Checks `notBefore` and `notAfter` timestamps against current system time
4. **Trust Anchor**: Verifies the root certificate exists in the system's trusted certificate store
5. **Revocation Status**: Checks OCSP/CRL when available to detect revoked certificates
6. **Hostname Verification**: Validates the requested hostname matches the certificate's Common Name (CN) or Subject Alternative Names (SAN)

```swift
final class TLSAuditor: NSObject, TLSAuditing, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, ...) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            capturedTrust = trust
            
            // CRYPTOGRAPHIC validation - returns false if ANY security check fails
            var error: CFError?
            let trusted = SecTrustEvaluateWithError(trust, &error)
            
            // Extract leaf certificate for detailed inspection
            let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate]
            let leaf = chain?.first
        }
    }
}
```

**macOS-specific certificate introspection** using X.509 OID-based ASN.1 parsing:
```swift
#if os(macOS)
private static func issuerSummary_macOS(from cert: SecCertificate) -> String? {
    // Extract issuer using standard X.509 OIDs
    let keys: [CFString] = [kSecOIDX509V1IssuerName]
    let values = SecCertificateCopyValues(cert, keys as CFArray, nil)
    // Parse CN (OID 2.5.4.3) and Organization (OID 2.5.4.10) from DER-encoded issuer
}

private static func notAfterDate_macOS(from cert: SecCertificate) -> Date? {
    // Extract validity period using X.509 validity OID
    let keys: [CFString] = [kSecOIDX509V1ValidityNotAfter]
    // Handle multiple date encoding formats (Unix timestamp, Apple reference date)
}
#endif
```

### EXIF Metadata Stripping Engine

The Privacy Guard implements a **lossless metadata stripping pipeline** using ImageIO:

```swift
struct MetadataStripper: Sendable {
    func stripMetadata(from data: Data) throws -> (data: Data, fileExtension: String) {
        // 1. Create thumbnail at full resolution (bakes in orientation)
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true  // Fixes rotation
        ]
        
        // 2. Re-encode without metadata dictionaries
        CGImageDestinationAddImage(dest, cgImage, nil)  // nil = no metadata
        
        return (strippedData, preferredExtension)
    }
}
```

**Key design decisions:**
- **Orientation baking**: Transform is applied during thumbnail creation, fixing rotation permanently
- **Format preservation**: Original UTType is maintained (JPEG, PNG, HEIC)
- **Full resolution**: Max pixel size is extracted from source to preserve quality

### Protocol-Oriented Service Layer

Services are defined via **protocols for dependency injection and testability**:

```swift
protocol BreachCheckServicing: Sendable {
    func check(emailAddress: String) async throws -> BreachCheckResult
}

protocol TLSAuditing: Sendable {
    func audit(url: URL) async throws -> TLSAuditResult
}

protocol OriginalPhotoLoading: Sendable {
    func loadOriginalData(for ref: PhotoItemReference) async throws -> Data
}
```

**Service Resolution Pattern:**
```swift
enum BreachCheckServiceResolver {
    static func resolve(preferredMode: BreachCheckServiceMode) -> BreachCheckServiceResolution {
        switch preferredMode {
        case .stub: return .init(service: StubBreachCheckService(), modeInUse: .stub)
        case .live:
            guard let key = HIBPAPIKeyStore.load() else { return fallbackToStub() }
            return .init(service: makeLiveService(apiKey: key), modeInUse: .live)
        case .automatic:
            // Smart resolution based on available credentials
        }
    }
}
```

---

## Design System

GuardianHub implements a **comprehensive design system** (`GuardianTheme`) for consistent visual language:

### Section-Based Color Gradients
```swift
enum SectionColor {
    case dashboard      // Purple: #667EEA → #764BA2
    case identityCheck  // Pink: #F093FB → #F5576C
    case webAuditor     // Cyan: #4FACFE → #00F2FE
    case privacyGuard   // Green: #43E97B → #38F9D7
    case passwordLab    // Coral: #FA709A → #FEE140
}
```

### Reusable View Modifiers
```swift
extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View { ... }
    func gradientCard(_ gradient: LinearGradient) -> some View { ... }
    func sectionCard(_ section: SectionColor) -> some View { ... }
    func shimmer() -> some View { ... }
}
```

### Animated Components
- **`AnimatedGradientRing`**: Progress indicators with spring animations
- **`AnimatedGradientBar`**: Horizontal progress bars with smooth transitions
- **`PulsingDot`**: Status indicators with repeating animations
- **`ShimmerModifier`**: Loading state shimmer effect

---

## Best Practices Demonstrated

### Swift Concurrency
- **`async/await`** throughout the codebase for asynchronous operations
- **`actor` isolation** for thread-safe photo processing (`PhotoAuditProcessor`)
- **`@Sendable` conformance** on all service types and closures
- **Structured concurrency** with parallel async let for concurrent network calls:
  ```swift
  async let headerResult = headerAuditor.audit(url: url)
  async let tlsResult = tlsAuditor.audit(url: url)
  let (headers, tls) = try await (headerResult, tlsResult)
  ```

### Modern SwiftUI Patterns
- **`@Observable` macro** (Swift 5.9+) for reactive state management
- **`@Query` macro** for declarative SwiftData fetching
- **`@Environment` injection** for dependency propagation
- **Conditional compilation** (`#if os(iOS)`) for platform-specific code

### Error Handling
- **`LocalizedError` conformance** with user-friendly messages
- **Typed error enums** per domain (`HIBPError`, `ExifReaderError`, `MetadataStripperError`)
- **Graceful degradation** (AI → rule-based, live → mock)

### Secure Coding
- **Keychain storage** for sensitive API keys
- **`SecTrust` evaluation** for TLS certificate validation
- **Memory-only processing** for password analysis (never persisted)
- **Proper authorization flows** for Photos library access

### Accessibility
- **`accessibilityLabel`** on interactive elements
- **Dynamic Type support** via system fonts
- **VoiceOver-friendly** component structure

---

## Platform Adaptations

| Feature | iOS | macOS |
|---------|-----|-------|
| Navigation | TabView (iPhone) / Split (iPad) | NavigationSplitView |
| Photo Import | PHPickerViewController | File-based with bookmarks |
| Export | Share Sheet (UIActivityViewController) | Folder Picker + Finder reveal |
| Haptics | CoreHaptics feedback | Not applicable |
| Certificate Details | Basic (system trust) | Full OID-based extraction |

Platform-specific implementations use file naming conventions:
```
OriginalPhotoLoader+iOS.swift
OriginalPhotoLoader+macOS.swift
StrippedFileExporter+macOS.swift
```

---

## Privacy & Security Considerations

| Feature | Privacy Approach |
|---------|------------------|
| Password Lab | **100% offline** - passwords never leave device memory |
| Web Auditor | Direct HTTPS connections - no proxy servers |
| Identity Check | API key stored in Keychain, hashed email queries |
| Privacy Guard | Photos processed locally, originals never modified |
| AI Explanations | On-device Apple Intelligence, no cloud processing |

---

## Project Structure

```
GuardianHub/
├── GuardianHubApp.swift          # App entry point, SwiftData container
├── Navigation/
│   ├── AppSection.swift          # Type-safe section enum
│   ├── AppNavigationModel.swift  # Observable navigation state
│   ├── RootNavigationView.swift  # Platform-adaptive root
│   ├── PhoneTabView.swift        # iPhone tab navigation
│   └── SidebarSplitView.swift    # iPad/macOS sidebar
├── Features/
│   ├── Dashboard/                # Main overview screen
│   ├── IdentityCheck/            # HIBP breach monitoring
│   ├── WebAuditor/               # TLS & header analysis
│   ├── PrivacyGuard/             # Photo metadata tools
│   └── PasswordLab/              # Password strength analysis
├── Shared/
│   ├── Theme/                    # Design system
│   ├── Security/                 # Keychain utilities
│   ├── Validation/               # Email, URL validators
│   └── ShareSheet.swift          # iOS share integration
└── Assets.xcassets/              # App icons, colors
```

---

## Requirements

- **iOS 18.0+** / **macOS 15.0+**
- **Xcode 16.0+**
- **Swift 5.9+**
- Apple Intelligence (optional, for AI-powered explanations)

---

## Building & Running

1. Clone the repository
2. Open `code/GuardianHub.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run (⌘R)

For Identity Check with live HIBP data:
1. Obtain an API key from [haveibeenpwned.com](https://haveibeenpwned.com/API/Key)
2. Enter the key in the app's Identity Check settings

---

## Acknowledgments

- [Have I Been Pwned](https://haveibeenpwned.com) for the breach database API
- Apple's Security, ImageIO, and FoundationModels frameworks
- The 10,000 most common English words list for dictionary-based password analysis

---

*Developed as a university project at FHNW, demonstrating modern iOS/macOS development practices.*
