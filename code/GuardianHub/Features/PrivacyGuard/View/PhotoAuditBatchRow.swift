//
//  PhotoAuditBatchRow.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditBatchRow: View {
    let batch: PhotoAuditBatch

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(batch.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                Label("\(batch.items.count) photo(s)", systemImage: "photo.on.rectangle")
                Label(gpsCountText, systemImage: gpsCount > 0 ? "location" : "location.slash")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var title: String {
        if let source = batch.source, !source.isEmpty {
            return "Album (\(source))"
        }
        return "Album"
    }

    private var gpsCount: Int { batch.items.filter(\.hasGPS).count }

    private var gpsCountText: String {
        gpsCount > 0 ? "\(gpsCount) with GPS" : "No GPS"
    }

    private var accessibilitySummary: String {
        "\(title), \(batch.items.count) photos, \(gpsCountText)"
    }
}
