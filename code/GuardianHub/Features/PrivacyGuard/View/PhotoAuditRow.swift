//
//  PhotoAuditRow.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditRow: View {
    let audit: PhotoAudit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(titleText)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(audit.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                Label(audit.hasExif ? "EXIF" : "No EXIF",
                      systemImage: audit.hasExif ? "checkmark.seal" : "xmark.seal")
                    .labelStyle(.titleAndIcon)

                Label(audit.hasGPS ? "Location" : "No Location",
                      systemImage: audit.hasGPS ? "location" : "location.slash")
                    .labelStyle(.titleAndIcon)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var titleText: String {
        audit.originalFilename?.isEmpty == false ? (audit.originalFilename ?? "Photo") : "Photo"
    }

    private var accessibilitySummary: String {
        var parts: [String] = []
        parts.append(titleText)
        parts.append(audit.hasExif ? "EXIF present" : "No EXIF")
        parts.append(audit.hasGPS ? "Location present" : "No location")
        return parts.joined(separator: ", ")
    }
}
