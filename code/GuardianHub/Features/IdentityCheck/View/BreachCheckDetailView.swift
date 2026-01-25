import SwiftUI
import SwiftData

struct BreachCheckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(IdentityCheckRuntimeSettings.self) private var runtimeSettings


    let check: BreachCheck

    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var rateLimitedUntil: Date?


    private var resolution: BreachCheckServiceResolution {
        BreachCheckServiceResolver.resolve(preferredMode: runtimeSettings.preferredMode)
    }

    

    var body: some View {
        List {
            // Status section at the top
            Section {
                HStack {
                    Label(
                        check.breachCount > 0 ? "Attention required" : "No issues stored",
                        systemImage: "shield.lefthalf.filled"
                    )
                    Spacer()
                    Text(check.breachCount > 0 ? "Risk" : "OK")
                        .foregroundStyle(check.breachCount > 0 ? .orange : .secondary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            if isRateLimited {
                Section {
                    RateLimitNoticeView(until: rateLimitedUntil ?? .now)
                }
            }
            
            IdentityCheckDataSourceSection(resolutionText: resolution.reason)

            HIBPAPIKeySection()

            Section("Summary") {
                LabeledContent("Email", value: check.emailAddress)
                LabeledContent("Breaches", value: "\(check.breachCount)")
                LabeledContent(
                    "Created",
                    value: check.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
                LabeledContent(
                    "Last Checked",
                    value: check.lastCheckedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
                )
            }

            Section("History") {
                if check.events.isEmpty {
                    ContentUnavailableView(
                        "No breach history stored",
                        systemImage: "tray",
                        description: Text("Once you run a check, breach events will appear here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(check.events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.breachName)
                                .font(.headline)

                            if let occurredAt = event.occurredAt {
                                Text(
                                    "Occurred: \(occurredAt.formatted(date: .abbreviated, time: .omitted))"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Breach Check")
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
