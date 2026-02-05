//
//  PrivacyGuardSummaryTile.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PrivacyGuardSummaryTile: View {
    @Query(sort: \PhotoAuditBatch.createdAt, order: .reverse) private var batches: [PhotoAuditBatch]
    @Query(sort: \PhotoAuditItem.createdAt, order: .reverse) private var items: [PhotoAuditItem]

    let onOpen: () -> Void
    
    private let sectionGradient = GuardianTheme.SectionColor.privacyGuard.gradient

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()
                .overlay(sectionGradient.opacity(0.3))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Albums", value: "\(batchCount)", highlight: false)
                metric(title: "Photos", value: "\(photoCount)", highlight: false)
                strippedMetric
            }
        }
        .padding(16)
        .background {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(sectionGradient.opacity(0.08))

                // Gradient accent bar
                Rectangle()
                    .fill(accentGradient)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .shadow(color: GuardianTheme.SectionColor.privacyGuard.primaryColor.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(sectionGradient.opacity(0.25), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            // Gradient icon background
            ZStack {
                Circle()
                    .fill(sectionGradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Privacy Guard")
                    .font(.headline)

                HStack(spacing: 6) {
                    if gpsCount > 0 {
                        PulsingDot(color: GuardianTheme.StatusGradient.warning.primaryColor, size: 6)
                    }
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onOpen) {
                HStack(spacing: 4) {
                    Text("Open")
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(GuardianTheme.SectionColor.privacyGuard.primaryColor)
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.flexible(minimum: 80), alignment: .leading),
            GridItem(.flexible(minimum: 90), alignment: .leading)
        ]
    }

    private var batchCount: Int { batches.count }
    private var photoCount: Int { items.count }
    private var gpsCount: Int { items.filter(\.hasGPS).count }
    private var strippedTotal: Int { items.filter(\.hasBeenStripped).count }

    private var statusText: String {
        if photoCount == 0 { return "No photos audited yet" }
        if gpsCount > 0 { return "\(gpsCount) item(s) expose location" }
        return "No location exposure detected"
    }

    private var accentGradient: LinearGradient {
        if gpsCount > 0 {
            return GuardianTheme.StatusGradient.warning.gradient
        }
        return sectionGradient
    }

    private func metric(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(highlight ? AnyShapeStyle(GuardianTheme.StatusGradient.warning.gradient) : AnyShapeStyle(.primary))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
    
    private var strippedMetric: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stripped")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 6) {
                if strippedTotal > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(GuardianTheme.StatusGradient.success.gradient)
                }
                
                Text("\(strippedTotal)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(strippedTotal > 0 ? AnyShapeStyle(GuardianTheme.StatusGradient.success.gradient) : AnyShapeStyle(.primary))
            }
        }
    }
}
