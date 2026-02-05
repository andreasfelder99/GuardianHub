import SwiftUI
import Charts

struct EntropyBreakdownCard: View {
    let result: PasswordAnalysisResult
    
    private let sectionGradient = GuardianTheme.SectionColor.passwordLab.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.headline)
                        .foregroundStyle(sectionGradient)
                    
                    Text("Entropy Breakdown")
                        .font(.headline)
                }
                Spacer()
                if result.passwordLength > 0 {
                    Text("\(Int(result.entropyBits.rounded())) bits")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(sectionGradient)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(sectionGradient.opacity(0.12))
                        }
                }
            }

            if result.passwordLength == 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis.ascending")
                            .font(.largeTitle)
                            .foregroundStyle(sectionGradient.opacity(0.4))
                        Text("Baseline and deductions will appear here as you type.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                Chart {
                    ForEach(chartData, id: \.label) { item in
                        BarMark(
                            x: .value("Bits", item.bits),
                            y: .value("Rule", item.label)
                        )
                        .foregroundStyle(item.bits >= 0 ? GuardianTheme.StatusGradient.success.gradient : GuardianTheme.StatusGradient.warning.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing, alignment: .center) {
                            Text(formattedBits(item.bits))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(item.bits >= 0 ? GuardianTheme.StatusGradient.success.primaryColor : GuardianTheme.StatusGradient.warning.primaryColor)
                        }
                    }
                }
                .frame(minHeight: 160)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(.primary)
                    }
                }

                Divider()
                    .overlay(sectionGradient.opacity(0.2))

                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How this works")
                            .font(.subheadline.weight(.semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            explanationItem(
                                icon: "plus.circle.fill",
                                color: GuardianTheme.StatusGradient.success.primaryColor,
                                text: "Baseline: length × log₂(effective alphabet)"
                            )
                            explanationItem(
                                icon: "minus.circle.fill",
                                color: GuardianTheme.StatusGradient.warning.primaryColor,
                                text: "Deductions: common patterns reduce real-world complexity"
                            )
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(sectionGradient)
                        Text("Why these numbers?")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .tint(GuardianTheme.SectionColor.passwordLab.primaryColor)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(sectionGradient.opacity(0.15), lineWidth: 1)
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
    
    private func explanationItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
