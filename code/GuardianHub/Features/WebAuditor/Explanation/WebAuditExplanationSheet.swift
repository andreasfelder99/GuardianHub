import SwiftUI

struct WebAuditExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let snapshot: WebAuditScanSnapshot
    @State private var viewModel = WebAuditExplanationViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Explanation")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            viewModel.generate(from: snapshot)
                        } label: {
                            if viewModel.isGenerating {
                                ProgressView()
                            } else {
                                Text("Regenerate")
                            }
                        }
                        .disabled(viewModel.isGenerating)
                    }
                }
                .onAppear {
                    viewModel.generate(from: snapshot)
                }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 520)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isGenerating && viewModel.explanation == nil {
            VStack(spacing: 12) {
                ProgressView()
                Text("Generating explanation…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else if let explanation = viewModel.explanation {
            List {
                Section {
                    HStack {
                        Text(explanation.headline)
                            .font(.headline)
                        Spacer()
                        RiskBadge(level: explanation.riskLevel)
                    }
                }

                Section {
                    Text(viewModel.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !explanation.keyPoints.isEmpty {
                    Section("Key points") {
                        ForEach(explanation.keyPoints, id: \.self) { point in
                            Text(point)
                        }
                    }
                }

                if let why = explanation.whyTLSIsTrusted, !why.isEmpty {
                    Section("Why is TLS trusted?") {
                        Text(why)
                    }
                }

                if !explanation.nextSteps.isEmpty {
                    Section("Recommended next steps") {
                        ForEach(explanation.nextSteps, id: \.self) { step in
                            Text(step)
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Explanation",
                systemImage: "sparkles",
                description: Text("Try again.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

private struct RiskBadge: View {
    let level: WebAuditExplanation.RiskLevel

    var body: some View {
        Text(label)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
            .overlay(
                Capsule().strokeBorder(borderStyle, lineWidth: 1)
            )
            .foregroundStyle(foregroundColor)
    }

    private var label: String {
        switch level {
        case .ok: return "OK"
        case .review: return "Review"
        case .high: return "High"
        }
    }

    private var foregroundColor: Color {
        switch level {
        case .ok: return .green
        case .review: return .orange
        case .high: return .red
        }
    }

    private var borderStyle: AnyShapeStyle {
        switch level {
        case .ok: return AnyShapeStyle(Color.green.opacity(0.35))
        case .review: return AnyShapeStyle(Color.orange.opacity(0.35))
        case .high: return AnyShapeStyle(Color.red.opacity(0.35))
        }
    }
}
