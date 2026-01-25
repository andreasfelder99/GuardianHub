import Foundation
import Security

final class TLSAuditor: NSObject, TLSAuditing, URLSessionDelegate {
    private var continuation: CheckedContinuation<TLSAuditResult, Error>?
    private var capturedTrust: SecTrust?

    func audit(url: URL) async throws -> TLSAuditResult {
        guard url.scheme?.lowercased() == "https" else {
            return TLSAuditResult(
                scannedAt: .now,
                isTrusted: false,
                certificateCommonName: nil,
                certificateIssuer: nil,
                certificateValidUntil: nil,
                summary: "TLS not applicable (non-HTTPS URL)"
            )
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            self.capturedTrust = nil

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 15

            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"

            let task = session.dataTask(with: request) { _, _, error in
                // If we never captured trust, we cannot evaluate TLS meaningfully.
                if let error, self.capturedTrust == nil {
                    self.finish(with: .failure(error))
                    return
                }

                self.finish(with: .success(self.buildResult()))
            }

            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {

            capturedTrust = trust

            let trusted = Self.evaluateTrust(trust)
            if trusted {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            return
        }

        completionHandler(.performDefaultHandling, nil)
    }

    private func buildResult() -> TLSAuditResult {
        let trust = capturedTrust

        let isTrusted = trust.map(Self.evaluateTrust) ?? false
        let leaf = trust.flatMap(Self.leafCertificate(from:))
        let commonName = leaf.flatMap(Self.subjectSummary(from:))

        #if os(macOS)
        let issuer = leaf.flatMap(Self.issuerSummary_macOS(from:))
        let validUntil = leaf.flatMap(Self.notAfterDate_macOS(from:))
        #else
        let issuer: String? = nil
        let validUntil: Date? = nil
        #endif

        let summary: String
        if trust == nil {
            summary = "TLS trust not evaluated"
        } else if isTrusted {
            #if os(iOS)
            summary = "TLS trusted, system trust evaluation passed (for full certificate details, use the macOS app)"
            #else
            summary = "TLS trusted, system trust evaluation passed"
            #endif
        } else {
            #if os(iOS)
            summary = "TLS trust failed, system trust evaluation failed (for full certificate details, use the macOS app)"
            #else
            summary = "TLS trust failed, system trust evaluation failed"
            #endif
        }

        return TLSAuditResult(
            scannedAt: .now,
            isTrusted: isTrusted,
            certificateCommonName: commonName,
            certificateIssuer: issuer,
            certificateValidUntil: validUntil,
            summary: summary
        )
    }

    private func finish(with result: Result<TLSAuditResult, Error>) {
        guard let cont = continuation else { return }
        continuation = nil

        switch result {
        case .success(let value):
            cont.resume(returning: value)
        case .failure(let error):
            cont.resume(throwing: error)
        }
    }

    // MARK: - Cross-platform helpers

    private static func evaluateTrust(_ trust: SecTrust) -> Bool {
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }

    private static func leafCertificate(from trust: SecTrust) -> SecCertificate? {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = chain.first else {
            return nil
        }
        return leaf
    }

    private static func subjectSummary(from cert: SecCertificate) -> String? {
        SecCertificateCopySubjectSummary(cert) as String?
    }

    // MARK: - macOS-only certificate details (OID-based)

    #if os(macOS)
    private static func issuerSummary_macOS(from cert: SecCertificate) -> String? {
        let keys: [CFString] = [kSecOIDX509V1IssuerName]

        guard
            let values = SecCertificateCopyValues(cert, keys as CFArray, nil) as? [CFString: Any],
            let issuerDict = values[kSecOIDX509V1IssuerName] as? [CFString: Any],
            let raw = issuerDict[kSecPropertyKeyValue]
        else {
            return nil
        }

        // The issuer value is typically an array of attribute dictionaries.
        // We extract a human-friendly issuer string (CN preferred, else O).
        if let items = raw as? [[CFString: Any]] {
            func firstValue(forOID oid: String) -> String? {
                for item in items {
                    // label is often OID string like "2.5.4.3" (CN) / "2.5.4.10" (O)
                    let label = (item[kSecPropertyKeyLabel] as? String) ?? (item[kSecPropertyKeyLocalizedLabel] as? String)
                    let value = item[kSecPropertyKeyValue] as? String
                    if label == oid, let value, !value.isEmpty { return value }
                }
                return nil
            }

            // OIDs we care about:
            // CN: 2.5.4.3, O: 2.5.4.10, C: 2.5.4.6
            let cn = firstValue(forOID: "2.5.4.3")
            let org = firstValue(forOID: "2.5.4.10")

            if let cn, let org, cn != org {
                return "\(cn) (\(org))"
            }
            return cn ?? org
        }

        // Fallback: at least avoid dumping the entire structure
        if let s = raw as? String, !s.isEmpty { return s }
        return nil
    }

    private static func notAfterDate_macOS(from cert: SecCertificate) -> Date? {
        let keys: [CFString] = [kSecOIDX509V1ValidityNotAfter]

        guard
            let values = SecCertificateCopyValues(cert, keys as CFArray, nil) as? [CFString: Any],
            let validity = values[kSecOIDX509V1ValidityNotAfter] as? [CFString: Any],
            let raw = validity[kSecPropertyKeyValue]
        else {
            return nil
        }

        if let date = raw as? Date { return date }

        if let number = raw as? NSNumber {
            return dateFromCertificateNumber(number)
        }

        if let dict = raw as? [CFString: Any],
        let inner = dict[kSecPropertyKeyValue] {
            if let date = inner as? Date { return date }
            if let number = inner as? NSNumber { return dateFromCertificateNumber(number) }
        }

        return nil
    }

    private static func dateFromCertificateNumber(_ number: NSNumber) -> Date? {
        let v = number.doubleValue

        // Heuristic sanity window: certificates are typically valid between year 2000 and 2050.
        func isSane(_ date: Date) -> Bool {
            let y = Calendar(identifier: .gregorian).component(.year, from: date)
            return (2000...2055).contains(y)
        }

        // 1) seconds since 1970
        let unixSeconds = Date(timeIntervalSince1970: v)
        if isSane(unixSeconds) { return unixSeconds }

        // 2) seconds since Apple reference date (2001-01-01)
        let refSeconds = Date(timeIntervalSinceReferenceDate: v)
        if isSane(refSeconds) { return refSeconds }

        // 3) milliseconds since 1970
        let unixMillis = Date(timeIntervalSince1970: v / 1000.0)
        if isSane(unixMillis) { return unixMillis }

        // 4) milliseconds since reference date
        let refMillis = Date(timeIntervalSinceReferenceDate: v / 1000.0)
        if isSane(refMillis) { return refMillis }

        return nil
    }
    #endif
}
