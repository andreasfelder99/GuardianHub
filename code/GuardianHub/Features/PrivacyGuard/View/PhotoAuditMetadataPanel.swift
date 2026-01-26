//
//  PhotoAuditItemMetadataPanel.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditItemMetadataPanel: View {
    let item: PhotoAuditItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)

            Form {
                Section {
                    LabeledContent("EXIF") {
                        Text(item.hasExif ? "Present" : "Not present")
                            .foregroundStyle(item.hasExif ? .primary : .secondary)
                    }
                    LabeledContent("GPS") {
                        Text(item.hasGPS ? "Present" : "Not present")
                            .foregroundStyle(item.hasGPS ? .primary : .secondary)
                    }
                    LabeledContent("Camera Make") {
                        Text(item.cameraMake ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Camera Model") {
                        Text(item.cameraModel ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Coordinates") {
                    if let lat = item.latitude, let lon = item.longitude {
                        LabeledContent("Latitude") { Text("\(lat)").foregroundStyle(.secondary) }
                        LabeledContent("Longitude") { Text("\(lon)").foregroundStyle(.secondary) }
                    } else {
                        Text("No location data was recorded for this photo.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDisabled(true) // keeps the outer ScrollView in control
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
