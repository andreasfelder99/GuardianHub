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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Albums", value: "\(batchCount)")
                metric(title: "Photos", value: "\(photoCount)")
                metric(title: "Stripped", value: "\(strippedTotal)")
            }
        }
        .padding(16)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)

                if let accentColor {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderStyle, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Privacy Guard", systemImage: "photo.badge.shield.checkmark")
                    .font(.headline)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onOpen) {
                Label("Open", systemImage: "arrow.right")
            }
            .buttonStyle(.bordered)
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
    private var strippedTotal: Int { batches.reduce(0) { $0 + $1.strippedPhotoCount } }

    private var statusText: String {
        if photoCount == 0 { return "No photos audited yet" }
        if gpsCount > 0 { return "\(gpsCount) item(s) expose location" }
        return "No location exposure detected"
    }

    private var accentColor: Color? {
        guard photoCount > 0 else { return nil }
        return gpsCount > 0 ? .orange : nil
    }

    private var borderStyle: AnyShapeStyle {
        gpsCount > 0 ? AnyShapeStyle(Color.orange.opacity(0.35)) : AnyShapeStyle(.quaternary)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}
