import SwiftUI

struct BreachCheckDetailView: View {
    let check: BreachCheck

    var body: some View {
        List {
            Section {
                HStack {
                    Label(check.breachCount > 0 ? "Attention required" : "No issues identified", systemImage: "shield.lefthalf.filled")
                    Spacer()
                    Text(check.breachCount > 0 ? "Risk" : "OK")
                        .foregroundStyle(check.breachCount > 0 ? .orange : .secondary)
                }
            }
            Section("Summary") {
                LabeledContent("Email", value: check.emailAddress)
                LabeledContent("Breaches", value: "\(check.breachCount)")
                LabeledContent("Created", value: check.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Last Checked", value: check.lastCheckedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
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
                                Text("Occurred: \(occurredAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Breach Check")
    }
}
