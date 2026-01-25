import Foundation

struct RuleBasedWebAuditExplainer: WebAuditExplanationBuilding {
    func explain(snapshot: WebAuditScanSnapshot) async -> WebAuditExplanation {
        let tlsOK = snapshot.isTLSValid
        let missingHeaders = missingHeaderNames(snapshot: snapshot)

        let risk: WebAuditExplanation.RiskLevel
        if snapshot.scannedAt == nil {
            risk = .review
        } else if !tlsOK {
            risk = .high
        } else if !missingHeaders.isEmpty {
            risk = .review
        } else {
            risk = .ok
        }

        let headline: String = switch risk {
        case .ok: "Looks good"
        case .review: "Improvements recommended"
        case .high: "Action recommended"
        }

        var keyPoints: [String] = []
        if snapshot.scannedAt == nil {
            keyPoints.append("This site hasn’t been scanned yet.")
        } else {
            keyPoints.append("TLS: \(snapshot.tlsSummary)")
            keyPoints.append("Headers: \(snapshot.headerSummary)")
        }

        if !missingHeaders.isEmpty {
            keyPoints.append("Missing recommended headers: \(missingHeaders.joined(separator: ", ")).")
        }

        if let note = snapshot.platformNote {
            keyPoints.append(note)
        }

        var nextSteps: [String] = []
        if snapshot.scannedAt != nil && !tlsOK {
            nextSteps.append("Verify the certificate chain and hostname match, and ensure the server presents a valid, trusted certificate.")
        }
        if snapshot.scannedAt != nil && !snapshot.hasHSTS {
            nextSteps.append("Enable HSTS to enforce HTTPS and reduce downgrade risks.")
        }
        if snapshot.scannedAt != nil && !snapshot.hasCSP {
            nextSteps.append("Add a Content Security Policy (CSP) to reduce XSS impact.")
        }
        if nextSteps.isEmpty {
            nextSteps.append("No immediate changes required. Re-scan periodically.")
        }

        let whyTLS = (snapshot.scannedAt != nil && tlsOK)
            ? "The system trust evaluation passed, meaning the OS considers the server certificate chain valid and trusted for this connection."
            : nil

        return WebAuditExplanation(
            headline: headline,
            riskLevel: risk,
            keyPoints: keyPoints,
            nextSteps: nextSteps,
            whyTLSIsTrusted: whyTLS
        )
    }

    private func missingHeaderNames(snapshot: WebAuditScanSnapshot) -> [String] {
        var missing: [String] = []
        if !snapshot.hasHSTS { missing.append("HSTS") }
        if !snapshot.hasCSP { missing.append("CSP") }
        return missing
    }
}

