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
            // Optional: instructions improve safety + consistency (per docs you pasted).
            let instructions = """
            You are a security assistant for a website audit tool.
            ALWAYS explain findings in plain language for a non-technical user.
            Keep output concise and practical. Avoid fear-mongering.
            """

            let session = LanguageModelSession(instructions: instructions)
            let prompt = makePrompt(snapshot: snapshot)

            let response = try await session.respond(
                to: prompt,
                generating: WebAuditExplanation.self
            )

            return response.content

        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Docs: rephrase prompt or show a clear message; here we just fall back safely.
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
        Explain this website scan in plain language.

        Output requirements:
        - headline: short and reassuring
        - riskLevel: ok, review, or high
        - keyPoints: 3-6 bullet points
        - nextSteps: 2-5 actionable steps
        - whyTLSIsTrusted: if TLS trusted is true, explain why; otherwise null

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
