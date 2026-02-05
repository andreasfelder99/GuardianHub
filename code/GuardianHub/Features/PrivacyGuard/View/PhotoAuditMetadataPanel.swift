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
    
    private var hasPrivacyRisks: Bool {
        item.hasGPS || item.cameraMake != nil || item.cameraModel != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hidden Photo Data")
                    .font(.headline)

                Spacer()

                Button {
                    onExportSelected()
                } label: {
                    #if os(macOS)
                    Label("Export Clean", systemImage: "square.and.arrow.down")
                    #else
                    Label("Share Clean", systemImage: "square.and.arrow.up")
                    #endif
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if hasPrivacyRisks {
                privacyWarningBanner
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Embedded Data") {
                        Text(item.hasExif ? "Found" : "None")
                            .foregroundStyle(item.hasExif ? .orange : .secondary)
                    }
                    LabeledContent("Location Tracking") {
                        HStack(spacing: 4) {
                            if item.hasGPS {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                            Text(item.hasGPS ? "GPS found" : "Not found")
                                .foregroundStyle(item.hasGPS ? .orange : .secondary)
                        }
                    }
                    LabeledContent("Device Brand") {
                        Text(item.cameraMake ?? "Not recorded")
                            .foregroundStyle(item.cameraMake != nil ? .primary : .secondary)
                    }
                    LabeledContent("Device Model") {
                        Text(item.cameraModel ?? "Not recorded")
                            .foregroundStyle(item.cameraModel != nil ? .primary : .secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Label("Device & Metadata", systemImage: "info.circle")
                    .font(.subheadline.weight(.medium))
            }

            GroupBox {
                if let lat = item.latitude, let lon = item.longitude {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.orange)
                            Text("This photo reveals where it was taken")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledContent("Latitude") { Text("\(lat)").foregroundStyle(.secondary) }
                            LabeledContent("Longitude") { Text("\(lon)").foregroundStyle(.secondary) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        CoordinateMapPreview(latitude: lat, longitude: lon)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("No location data found in this photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } label: {
                Label("Location Data", systemImage: "location")
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var privacyWarningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Privacy Risk Detected")
                    .font(.subheadline.weight(.semibold))
                Text("This photo contains data that could identify you or your location. Use \"Share Clean Copy\" to remove it before sharing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
