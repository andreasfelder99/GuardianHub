//
//  PhotoAuditItemMetadataPanel.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditItemMetadataPanel: View {
    let item: PhotoAuditItem

    // Callbacks provided by parent (batch detail view)
    let onExportSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Metadata")
                    .font(.headline)

                Spacer()

                Button {
                    onExportSelected()
                } label: {
                    #if os(macOS)
                    Label("Export Selected", systemImage: "square.and.arrow.down")
                    #else
                    Label("Share Selected", systemImage: "square.and.arrow.up")
                    #endif
                }
                .buttonStyle(.bordered)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Coordinates") {
                if let lat = item.latitude, let lon = item.longitude {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledContent("Latitude") { Text("\(lat)").foregroundStyle(.secondary) }
                            LabeledContent("Longitude") { Text("\(lon)").foregroundStyle(.secondary) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        CoordinateMapPreview(latitude: lat, longitude: lon)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No location data was recorded for this photo.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
