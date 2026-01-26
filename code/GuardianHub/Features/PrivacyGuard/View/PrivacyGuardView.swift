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

    @Query(sort: \PhotoAuditBatch.createdAt, order: .reverse)
    private var batches: [PhotoAuditBatch]

    @State private var isPresentingImportSheet = false

    @State private var errorMessage: String?
    @State private var isShowingError = false

    // Background processor (actor) for EXIF + thumbnail generation
    private let processor = PhotoAuditProcessor()

    var body: some View {
        Group {
            if batches.isEmpty {
                ContentUnavailableView(
                    "No Photo Albums",
                    systemImage: "photo.badge.shield.checkmark",
                    description: Text("Import one or more photos to inspect EXIF metadata and location data.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    Button {
                        isPresentingImportSheet = true
                    } label: {
                        Label("Import Photos", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                List {
                    Section {
                        ForEach(batches) { batch in
                            NavigationLink {
                                PhotoAuditBatchDetailView(batch: batch)
                            } label: {
                                PhotoAuditBatchRow(batch: batch)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(batch)
                                } label: {
                                    Label("Delete Album", systemImage: "trash")
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
                    Task {
                        await persistBatch(from: imported)
                    }
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
            modelContext.delete(batches[index])
        }
    }

    @MainActor
    private func persistBatch(from imported: [ImportedPhoto]) async {
        do {
            let source = imported.first?.source
            let drafts = try await processor.process(imported)

            let batch = PhotoAuditBatch(source: source)
            for draft in drafts {
                let item = PhotoAuditItem(
                    originalFilename: draft.originalFilename,
                    hasExif: draft.hasExif,
                    hasGPS: draft.hasGPS,
                    latitude: draft.latitude,
                    longitude: draft.longitude,
                    cameraMake: draft.cameraMake,
                    cameraModel: draft.cameraModel,
                    thumbnailJPEG: draft.thumbnailJPEG,
                    assetIdentifier: draft.assetIdentifier,
                    fileBookmark: draft.fileBookmark
                )
                batch.items.append(item)
            }

            modelContext.insert(batch)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
        }
    }
}
