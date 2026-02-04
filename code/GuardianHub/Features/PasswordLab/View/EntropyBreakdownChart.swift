import SwiftUI
import Charts

struct EntropyBreakdownCard: View {
    let result: PasswordAnalysisResult

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Entropy Breakdown", systemImage: "chart.bar.xaxis")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(result.entropyBits.rounded())) bits")
                        .foregroundStyle(.secondary)
                }

                if result.passwordLength == 0 {
                    Text("Baseline and deductions will appear here as you type.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(chartData, id: \.label) { item in
                            BarMark(
                                x: .value("Bits", item.bits),
                                y: .value("Rule", item.label)
                            )
                            .annotation(position: .trailing, alignment: .center) {
                                Text(formattedBits(item.bits))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(minHeight: 160)
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    Divider()

                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How this works")
                                .font(.subheadline.weight(.semibold))
                            Text("""
                            We estimate entropy from two transparent parts:
                            • Baseline: length * log2(effective alphabet)
                            • Deductions: common patterns (repetition, sequences, common passwords) reduce real-world complexity.
                            """)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    } label: {
                        Text("Why these numbers?")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        } label: {
            Text("Analysis")
        }
    }

    private var chartData: [EntropyComponent] {
        // Keep order stable as provided by the engine.
        result.breakdown
    }

    private func formattedBits(_ bits: Double) -> String {
        let rounded = Int(bits.rounded())
        if rounded > 0 { return "+\(rounded)" }
        return "\(rounded)"
    }
}
