//
//  PhotoAuditDetailView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditDetailView: View {
    let audit: PhotoAudit

    var body: some View {
        Form {
            Section("Summary") {
                LabeledContent("Created") {
                    Text(audit.createdAt.formatted())
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Filename") {
                    Text(audit.originalFilename ?? "—")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Source") {
                    Text(audit.source ?? "—")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Metadata") {
                LabeledContent("EXIF") {
                    Text(audit.hasExif ? "Present" : "Not present")
                        .foregroundStyle(audit.hasExif ? .primary : .secondary)
                }
                LabeledContent("GPS") {
                    Text(audit.hasGPS ? "Present" : "Not present")
                        .foregroundStyle(audit.hasGPS ? .primary : .secondary)
                }
                LabeledContent("Camera Make") {
                    Text(audit.cameraMake ?? "—")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Camera Model") {
                    Text(audit.cameraModel ?? "—")
                        .foregroundStyle(.secondary)
                }
            }

            if let lat = audit.latitude, let lon = audit.longitude {
                Section("Location") {
                    LabeledContent("Latitude") {
                        Text("\(lat)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Longitude") {
                        Text("\(lon)")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section("Location") {
                    Text("No location data was recorded for this photo.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Audit Details")
    }
}
