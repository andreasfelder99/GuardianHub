//
//  PrivacyGuardView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PrivacyGuardView: View {
    @Environment(\.modelContext) private var modelContext

    // newest first
    @Query(sort: \PhotoAudit.createdAt, order: .reverse)
    private var audits: [PhotoAudit]

    @State private var isPresentingImportSheet = false

    @State private var errorMessage: String?
    @State private var isShowingError = false

    var body: some View {
        Group {
            if audits.isEmpty {
                ContentUnavailableView(
                    "No Photo Audits",
                    systemImage: "photo.badge.shield.checkmark",
                    description: Text("Import a photo to inspect EXIF metadata and location data.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    Button {
                        isPresentingImportSheet = true
                    } label: {
                        Label("Import Photo", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                List {
                    Section {
                        ForEach(audits) { audit in
                            NavigationLink {
                                PhotoAuditDetailView(audit: audit)
                            } label: {
                                PhotoAuditRow(audit: audit)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(audit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
        }
        .navigationTitle("Privacy Guard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $isPresentingImportSheet) {
            PhotoImportSheet(
                onImported: { imported in
                    isPresentingImportSheet = false
                    Task { await persistAudit(from: imported) }
                },
                onCancel: {
                    isPresentingImportSheet = false
                }
            )
        }
        .alert("Privacy Guard Error", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(audits[index])
        }
    }

    @MainActor
    private func persistAudit(from imported: ImportedPhoto) async {
        do {
            let summary = try await Task.detached(priority: .userInitiated) {
                try await ExifReader().read(from: imported.data)
            }.value

            let audit = PhotoAudit(
                source: imported.source,
                originalFilename: imported.filename,
                hasExif: summary.hasExif,
                hasGPS: summary.hasGPS,
                latitude: summary.latitude,
                longitude: summary.longitude,
                cameraMake: summary.cameraMake,
                cameraModel: summary.cameraModel
            )

            modelContext.insert(audit)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
        }
    }
}
