//
//  PhotoAuditItemDetailView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditItemDetailView: View {
    let item: PhotoAuditItem

    var body: some View {
        Form {
            Section("Metadata") {
                LabeledContent("EXIF") { Text(item.hasExif ? "Present" : "Not present").foregroundStyle(item.hasExif ? .primary : .secondary) }
                LabeledContent("GPS") { Text(item.hasGPS ? "Present" : "Not present").foregroundStyle(item.hasGPS ? .primary : .secondary) }
                LabeledContent("Camera Make") { Text(item.cameraMake ?? "—").foregroundStyle(.secondary) }
                LabeledContent("Camera Model") { Text(item.cameraModel ?? "—").foregroundStyle(.secondary) }
            }

            if let lat = item.latitude, let lon = item.longitude {
                Section("Location") {
                    LabeledContent("Latitude") { Text("\(lat)").foregroundStyle(.secondary) }
                    LabeledContent("Longitude") { Text("\(lon)").foregroundStyle(.secondary) }
                }
            } else {
                Section("Location") {
                    Text("No location data was recorded for this photo.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(item.originalFilename ?? "Photo")
    }
}
