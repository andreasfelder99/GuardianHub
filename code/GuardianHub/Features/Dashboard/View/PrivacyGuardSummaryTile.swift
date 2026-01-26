//
//  PrivacyGuardSummaryTile.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PrivacyGuardSummaryTile: View {
    // newest first
    @Query(sort: \PhotoAudit.createdAt, order: .reverse) private var audits: [PhotoAudit]

    // callback when user wants to open Privacy Guard section
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                metric(title: "Audits", value: "\(totalCount)")
                metric(title: "With GPS", value: "\(gpsCount)")
                metric(title: "Last Audit", value: lastAuditText)
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
                Label("Privacy Guard", systemImage: "shield.lefthalf.filled")
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

    private var totalCount: Int {
        audits.count
    }

    private var gpsCount: Int {
        audits.filter(\.hasGPS).count
    }

    private var statusText: String {
        if totalCount == 0 { return "No photos audited yet" }
        if gpsCount > 0 { return "\(gpsCount) item(s) expose location" }
        return "No location exposure detected"
    }

    private var lastAuditText: String {
        guard let date = audits.first?.createdAt else { return "Never" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
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

    private var accentColor: Color? {
        guard totalCount > 0 else { return nil }
        return gpsCount > 0 ? .orange : nil
    }

    private var borderStyle: AnyShapeStyle {
        if gpsCount > 0 {
            return AnyShapeStyle(Color.orange.opacity(0.35))
        }
        return AnyShapeStyle(.quaternary)
    }
}
