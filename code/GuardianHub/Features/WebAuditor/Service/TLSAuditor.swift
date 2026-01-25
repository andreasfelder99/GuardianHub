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
                completionHandler(.performDefaultHandling, nil)
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
            summary = "TLS not evaluated"
        } else if isTrusted {
            #if os(iOS)
            summary = "TLS trusted (for full certificate details, use the macOS app)"
            #else
            summary = "TLS trusted"
            #endif
        } else {
            #if os(iOS)
            summary = "TLS trust failed (for full certificate details, use the macOS app)"
            #else
            summary = "TLS trust failed"
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
        // This uses OID parsing which is available on macOS; keep it best-effort.
        let keys: [CFString] = [kSecOIDX509V1IssuerName]
        guard let values = SecCertificateCopyValues(cert, keys as CFArray, nil) as? [CFString: Any],
              let issuerDict = values[kSecOIDX509V1IssuerName] as? [CFString: Any] else {
            return nil
        }

        if let issuerName = issuerDict[kSecPropertyKeyValue] {
            return String(describing: issuerName)
        }
        return nil
    }

    private static func notAfterDate_macOS(from cert: SecCertificate) -> Date? {
        let keys: [CFString] = [kSecOIDX509V1ValidityNotAfter]
        guard let values = SecCertificateCopyValues(cert, keys as CFArray, nil) as? [CFString: Any],
              let validity = values[kSecOIDX509V1ValidityNotAfter] as? [CFString: Any],
              let notAfter = validity[kSecPropertyKeyValue] else {
            return nil
        }

        if let date = notAfter as? Date { return date }
        if let cfDate = notAfter as? CFDate { return cfDate as Date }
        return nil
    }
    #endif
}
