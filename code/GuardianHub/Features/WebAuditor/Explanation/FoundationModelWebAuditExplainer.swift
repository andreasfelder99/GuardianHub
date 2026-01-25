import Foundation
import FoundationModels

struct FoundationModelsWebAuditExplainer: WebAuditExplanationBuilding {
    private let fallback = RuleBasedWebAuditExplainer()

    func explain(snapshot: WebAuditScanSnapshot) async -> WebAuditExplanation {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable:
            return await fallback.explain(snapshot: snapshot)
        @unknown default:
            return await fallback.explain(snapshot: snapshot)
        }

        do {
            let instructions = """
            You are a security assistant for a website audit tool.
            Provide technical explanations that explain both WHAT security features do and WHY they matter.
            For each security header or TLS configuration, explain:
            - What specific attacks or vulnerabilities it prevents
            - How the mechanism works technically
            - What risks exist when it's missing
            Keep explanations informative and technical while remaining accessible. Avoid fear-mongering.
            """

            let session = LanguageModelSession(instructions: instructions)
            let prompt = makePrompt(snapshot: snapshot)

            let response = try await session.respond(
                to: prompt,
                generating: WebAuditExplanation.self
            )

            return response.content

        } catch LanguageModelSession.GenerationError.guardrailViolation {
            return await fallback.explain(snapshot: snapshot)

        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let base = await fallback.explain(snapshot: snapshot)

            do {
                let refusalResponse = try await refusal.explanation
                let message = refusalResponse.content

                var adjusted = base
                adjusted.keyPoints.append(message)
                return adjusted
            } catch {
                return base
            }
        } catch {
            return await fallback.explain(snapshot: snapshot)
        }
    }

    private func makePrompt(snapshot: WebAuditScanSnapshot) -> String {
        """
        Explain this website security scan with technical depth.

        Output requirements:
        - headline: short and reassuring
        - riskLevel: ok, review, or high
        - keyPoints: 3-6 bullet points. For each security feature: Explain WHAT it does and WHY it matters (what attacks it prevents, how it works)
        - nextSteps: If any security headers (HSTS, CSP) are missing, list them and explain why the site is still trusted and safe despite their absence. Explain what each missing header does and why its absence is not unsafe (e.g., TLS still provides encryption, HTTPS is still enforced). If all headers are present, this can be empty or contain a brief note about the good security posture.
        - whyTLSIsTrusted: if TLS trusted is true, explain the certificate chain validation process in maximum 4 sentences (use plain text or properly formatted markdown); otherwise null

        For each security feature, explain:
        - HSTS: Explain that it prevents protocol downgrade attacks and man-in-the-middle attacks by forcing HTTPS. Explain how the browser enforces this and what max-age means. If missing, note that HTTPS is still enforced by the TLS connection itself, but HSTS adds an extra layer by preventing downgrade attacks on subsequent visits.
        - CSP: Explain that it mitigates XSS attacks by restricting which sources can load scripts, styles, and other resources. Explain how it prevents code injection. If missing, note that the site can still be secure if proper input validation and output encoding are implemented, but CSP provides defense-in-depth.
        - TLS: Explain what encryption provides (confidentiality, integrity, authentication) and what attacks it prevents (eavesdropping, tampering, impersonation).

        Scan:
        URL: \(snapshot.urlString)
        ScannedAt: \(snapshot.scannedAt?.formatted() ?? "never")

        TLS trusted: \(snapshot.isTLSValid ? "true" : "false")
        TLS summary: \(snapshot.tlsSummary)
        Certificate CN: \(snapshot.certificateCommonName ?? "unknown")
        Certificate issuer: \(snapshot.certificateIssuer ?? "unknown")
        Certificate valid until: \(snapshot.certificateValidUntil?.formatted() ?? "unknown")

        HSTS present: \(snapshot.hasHSTS ? "true" : "false")
        CSP present: \(snapshot.hasCSP ? "true" : "false")
        Header summary: \(snapshot.headerSummary)

        Platform note: \(snapshot.platformNote ?? "none")
        """
    }
}
