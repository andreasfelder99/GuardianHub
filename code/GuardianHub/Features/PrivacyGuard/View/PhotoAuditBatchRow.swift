//
//  PhotoAuditBatchRow.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditBatchRow: View {
    let batch: PhotoAuditBatch
    
    private var statusGradient: LinearGradient {
        gpsCount > 0 ? GuardianTheme.StatusGradient.warning.gradient : GuardianTheme.StatusGradient.success.gradient
    }
    
    private let sectionGradient = GuardianTheme.SectionColor.privacyGuard.gradient

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Album icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(sectionGradient.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "photo.stack")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(sectionGradient)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(batch.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    // Photo count badge
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption2)
                        Text("\(batch.items.count)")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                    
                    // GPS status badge
                    HStack(spacing: 4) {
                        Image(systemName: gpsCount > 0 ? "location.fill" : "location.slash")
                            .font(.caption2)
                        Text(gpsCountText)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(gpsCount > 0 ? GuardianTheme.StatusGradient.warning.primaryColor : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(batch.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if gpsCount > 0 {
                    Circle()
                        .fill(GuardianTheme.StatusGradient.warning.gradient)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var gpsCount: Int {
        batch.items.filter(\.hasGPS).count
    }

    private var gpsCountText: String {
        gpsCount > 0 ? "\(gpsCount) GPS" : "No GPS"
    }

    private var accessibilitySummary: String {
        "\(batch.title), \(batch.items.count) photos, \(gpsCountText)"
    }
}
