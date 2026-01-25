import Foundation
import FoundationModels

struct FoundationModelsWebAuditExplainer: WebAuditExplanationBuilding {
    private let fallback = RuleBasedWebAuditExplainer()

    func explain(snapshot: WebAuditScanSnapshot) async -> WebAuditExplanation {
        // Always compute risk in app logic (deterministic)
        let risk = computedRiskLevel(for: snapshot)

        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable:
            let base = await fallback.explain(snapshot: snapshot)
            return WebAuditExplanation(
                headline: base.headline,
                riskLevel: risk,
                keyPoints: base.keyPoints,
                nextSteps: base.nextSteps,
                whyTLSIsTrusted: base.whyTLSIsTrusted
            )
        @unknown default:
            let base = await fallback.explain(snapshot: snapshot)
            return WebAuditExplanation(
                headline: base.headline,
                riskLevel: risk,
                keyPoints: base.keyPoints,
                nextSteps: base.nextSteps,
                whyTLSIsTrusted: base.whyTLSIsTrusted
            )
        }

        do {
            let instructions = """
            You are a security analyst for a website audit tool.

            CRITICAL RULES:
            - Use ONLY the provided scan data.
            - Do NOT guess or invent certificate issuer, expiration dates, or authorities.
            - If a value is not available, say "not available" and explain it's a platform limitation (not a weakness).
            - Avoid fear-mongering. Be calm and precise.

            PLATFORM RULE:
            - If tlsMetadataUnavailableIsNormal is true, issuer/expiry being unavailable is expected on iOS.
            - Do NOT treat unavailable metadata as a security risk.
            - Only mention iOS or platform limitations if tlsMetadataUnavailableIsNormal is true. If false, do not mention iOS.
            """

            let session = LanguageModelSession(instructions: instructions)
            let prompt = makePrompt(snapshot: snapshot)

            let response = try await session.respond(
                to: prompt,
                generating: WebAuditExplanationDraft.self
            )

            let draft = response.content

            // Merge draft with deterministic risk level
            return WebAuditExplanation(
                headline: draft.headline,
                riskLevel: risk,
                keyPoints: draft.keyPoints,
                nextSteps: draft.nextSteps,
                whyTLSIsTrusted: draft.whyTLSIsTrusted
            )

        } catch LanguageModelSession.GenerationError.guardrailViolation {
            let base = await fallback.explain(snapshot: snapshot)
            return WebAuditExplanation(
                headline: base.headline,
                riskLevel: risk,
                keyPoints: base.keyPoints,
                nextSteps: base.nextSteps,
                whyTLSIsTrusted: base.whyTLSIsTrusted
            )

        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let base = await fallback.explain(snapshot: snapshot)

            do {
                let refusalResponse = try await refusal.explanation
                let message = refusalResponse.content

                var adjusted = base
                adjusted.keyPoints.append(message)

                return WebAuditExplanation(
                    headline: adjusted.headline,
                    riskLevel: risk,
                    keyPoints: adjusted.keyPoints,
                    nextSteps: adjusted.nextSteps,
                    whyTLSIsTrusted: adjusted.whyTLSIsTrusted
                )
            } catch {
                return WebAuditExplanation(
                    headline: base.headline,
                    riskLevel: risk,
                    keyPoints: base.keyPoints,
                    nextSteps: base.nextSteps,
                    whyTLSIsTrusted: base.whyTLSIsTrusted
                )
            }
        } catch {
            let base = await fallback.explain(snapshot: snapshot)
            return WebAuditExplanation(
                headline: base.headline,
                riskLevel: risk,
                keyPoints: base.keyPoints,
                nextSteps: base.nextSteps,
                whyTLSIsTrusted: base.whyTLSIsTrusted
            )
        }
    }

    private func computedRiskLevel(for snapshot: WebAuditScanSnapshot) -> WebAuditExplanation.RiskLevel {
        // Deterministic and platform-safe:
        // - issuer/expiry availability must not affect risk on iOS
        guard snapshot.scannedAt != nil else { return .review }

        if snapshot.isTLSValid == false { return .high }

        // Header posture: treat missing HSTS/CSP as review (defense-in-depth)
        if snapshot.hasHSTS == false || snapshot.hasCSP == false {
            return .review
        }

        return .ok
    }

    private func makePrompt(snapshot: WebAuditScanSnapshot) -> String {
        let platformBlock: String
        if snapshot.tlsMetadataUnavailableIsNormal {
            platformBlock = """
            tlsMetadataUnavailableIsNormal: true
            Platform note: \(snapshot.platformNote ?? "Not available")
            """
        } else {
            platformBlock = ""   // macOS: do not mention iOS at all
        }

        return """
        Create a concise explanation of this web security scan for a non-technical but informed user.

        OUTPUT:
        - headline: 6-10 words, specific to THIS scan (avoid generic definitions)
        - keyPoints: 3-5 short bullets, each must reference scan data
        - nextSteps: 2-4 actionable bullets (only suggest changes relevant to scan)
        - whyTLSIsTrusted: if TLS trusted is true, explain in max 3 sentences.
        If tlsMetadataUnavailableIsNormal is true, explicitly state issuer/expiry are not available on iOS and that this is expected.

        IMPORTANT RULE:
        If TLS trusted is true AND tlsMetadataUnavailableIsNormal is true,
        do NOT frame issuer/expiry as "unknown risk". Describe it as "not available on iOS".

        SCAN DATA:
        URL: \(snapshot.urlString)
        Last scanned: \(snapshot.scannedAt?.formatted() ?? "never")

        TLS trusted: \(snapshot.isTLSValid ? "true" : "false")
        TLS summary: \(snapshot.tlsSummary)
        Certificate CN: \(snapshot.certificateCommonName ?? "not available")
        Certificate issuer: \(snapshot.certificateIssuer ?? "not available")
        Certificate valid until: \(snapshot.certificateValidUntil?.formatted() ?? "not available")
        TLS details available: \(snapshot.tlsDetailsAvailable ? "true" : "false")

        HSTS present: \(snapshot.hasHSTS ? "true" : "false")
        CSP present: \(snapshot.hasCSP ? "true" : "false")
        Header summary: \(snapshot.headerSummary)

        \(platformBlock)
        """
    }    
}
