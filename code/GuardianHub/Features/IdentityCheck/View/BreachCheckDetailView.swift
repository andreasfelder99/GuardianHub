import SwiftUI
import SwiftData

struct BreachCheckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(IdentityCheckRuntimeSettings.self) private var runtimeSettings
    @Environment(HIBPAPIKeyNotifier.self) private var keyNotifier



    let check: BreachCheck

    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var rateLimitedUntil: Date?


    private var resolution: BreachCheckServiceResolution {
        _ = keyNotifier.revision // dependency anchor
        return BreachCheckServiceResolver.resolve(preferredMode: runtimeSettings.preferredMode)
    }


    

    var body: some View {
        List {
            // Status section at the top
            Section {
                HStack {
                    Label(
                        check.breachCount > 0 ? "Found in \(check.breachCount) breach\(check.breachCount == 1 ? "" : "es")" : "No breaches found",
                        systemImage: check.breachCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.shield.fill"
                    )
                    .foregroundStyle(check.breachCount > 0 ? .orange : .primary)
                    Spacer()
                    Text(check.breachCount > 0 ? "At Risk" : "Safe")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(check.breachCount > 0 ? .orange : .green)
                }
            } footer: {
                if check.breachCount > 0 {
                    Text("This email was found in data breaches. Consider changing passwords for affected accounts.")
                }
            }

            if isRateLimited {
                Section {
                    RateLimitNoticeView(until: rateLimitedUntil ?? .now)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            
            
            IdentityCheckDataSourceSection(resolutionText: resolution.reason)

            if runtimeSettings.preferredMode == .live && resolution.modeInUse != .live {
                Section {
                    Label(
                        "Live mode requires an API key. Add your key below or switch to Automatic/Mock.",
                        systemImage: "info.circle"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            HIBPAPIKeySection()

            Section("Email Details") {
                LabeledContent("Email", value: check.emailAddress)
                LabeledContent("Breaches Found", value: "\(check.breachCount)")
                LabeledContent(
                    "Added",
                    value: check.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
                LabeledContent(
                    "Last Checked",
                    value: check.lastCheckedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
                )
            }

            Section {
                if check.events.isEmpty {
                    ContentUnavailableView(
                        "No Breaches Recorded",
                        systemImage: "shield.checkered",
                        description: Text("Run a check to scan for data breaches involving this email.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(check.events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.breachName)
                                .font(.headline)

                            if let occurredAt = event.occurredAt {
                                Text(
                                    "Breach date: \(occurredAt.formatted(date: .abbreviated, time: .omitted))"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Breach History")
            } footer: {
                if !check.events.isEmpty {
                    Text("These are services where your email was found in leaked data. Change your password on any accounts you still use.")
                }
            }
        }
        .navigationTitle("Breach Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    runCheck()
                } label: {
                    if isRunning {
                        ProgressView()
                    } else if isRateLimited {
                        Label("Try Again (\(secondsUntilRetry)s)", systemImage: "hourglass")
                    } else {
                        Label("Run Check", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRunning || isRateLimited)
            }
        }
    }

    private func runCheck() {
        errorMessage = nil
        
        if let until = rateLimitedUntil, until <= .now {
            rateLimitedUntil = nil
        }

        isRunning = true

        Task {
            do {
                if let until = rateLimitedUntil, until <= .now {
                    rateLimitedUntil = nil
                }

                runtimeSettings.lastResolutionMessage = resolution.reason
                let result = try await resolution.service.check(emailAddress: check.emailAddress)
                await MainActor.run {
                    BreachCheckStore.apply(result, to: check)
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    if let hibpError = error as? HIBPError {
                        switch hibpError {
                        case .rateLimited(let retryAfterSeconds):
                            rateLimitedUntil = Date().addingTimeInterval(TimeInterval(retryAfterSeconds))
                            errorMessage = "Rate limit reached. Please wait \(retryAfterSeconds) seconds and try again."
                        default:
                            errorMessage = "Check failed: \(hibpError.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Check failed: \(error.localizedDescription)"
                    }
                    isRunning = false
                }
            }
        }
    }

    private var isRateLimited: Bool {
        if let until = rateLimitedUntil {
            return until > .now
        }
        return false
    }

    private var secondsUntilRetry: Int {
        guard let until = rateLimitedUntil else { return 0 }
        let seconds = Int(until.timeIntervalSinceNow.rounded(.up))
        return max(0, seconds)
    }

}
