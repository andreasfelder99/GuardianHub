//
//  PhotoAuditItemRow.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditItemRow: View {
    let item: PhotoAuditItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.originalFilename ?? "Photo")
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 10) {
                Label(item.hasExif ? "EXIF" : "No EXIF",
                      systemImage: item.hasExif ? "checkmark.seal" : "xmark.seal")
                Label(item.hasGPS ? "Location" : "No Location",
                      systemImage: item.hasGPS ? "location" : "location.slash")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
}
