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

    // Rename state (context menu)
    @State private var isPresentingRename = false
    @State private var renameDraftTitle = ""
    @State private var batchToRename: PhotoAuditBatch?

    // Export/share state (context menu)
    @State private var isPreparingExport = false
    @State private var exportBatch: PhotoAuditBatch?
    @State private var preparedURLs: [URL] = []

    // iOS share sheet
    @State private var isPresentingShareSheet = false

    // macOS export confirmation
    @State private var isShowingMacExportDone = false
    @State private var exportedFolderURL: URL?

    @State private var lastExportCount: Int?


    // Background processor (actor) for EXIF + thumbnail generation
    private let processor = PhotoAuditProcessor()

    // Reuse the same coordinator as in detail view
    private let exportCoordinator = StrippedExportCoordinator()

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
                                Button {
                                    Task { await exportAlbum(batch) }
                                } label: {
                                    #if os(macOS)
                                    Label("Export Stripped", systemImage: "square.and.arrow.down")
                                    #else
                                    Label("Share Stripped", systemImage: "square.and.arrow.up")
                                    #endif
                                }
                                .disabled(isPreparingExport || batch.items.isEmpty)

                                Divider()

                                Button {
                                    beginRename(batch)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                Divider()

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
            ToolbarItem(placement: .status) {
                if isPreparingExport {
                    ProgressView()
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
        // Rename alert
        .alert("Rename Album", isPresented: $isPresentingRename) {
            TextField("Album name", text: $renameDraftTitle)

            Button("Save") {
                saveRename()
            }

            Button("Cancel", role: .cancel) {
                batchToRename = nil
            }
        }
        // Generic error alert
        .alert("Privacy Guard Error", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        #if os(iOS)
        // iOS share sheet for list-level export
        .sheet(isPresented: $isPresentingShareSheet) {
            ShareSheet(activityItems: preparedURLs)
        }
        #endif
        #if os(macOS)
        // macOS export confirmation
        .alert("Export Complete", isPresented: $isShowingMacExportDone) {
            Button("Reveal in Finder") {
                if let url = exportedFolderURL {
                    StrippedFileExporter.revealInFinder(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportedFolderURL?.path ?? "Exported stripped images.")
        }
        #endif
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(batches[index])
        }
    }

    private func beginRename(_ batch: PhotoAuditBatch) {
        batchToRename = batch
        renameDraftTitle = batch.title
        isPresentingRename = true
    }

    @MainActor
    private func saveRename() {
        guard let batchToRename else { return }
        let trimmed = renameDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        batchToRename.title = trimmed
        self.batchToRename = nil
    }

    @MainActor
    private func exportAlbum(_ batch: PhotoAuditBatch) async {
        isPreparingExport = true
        defer { isPreparingExport = false }   // CRITICAL: never get stuck
        exportBatch = batch
        preparedURLs = []
        exportedFolderURL = nil

        do {
            #if os(iOS)
            try await PhotosAuthorization.ensureAuthorized()
            #endif

            let refs = exportCoordinator.refs(for: batch.items)
            let urls = try await exportCoordinator.prepareStrippedFiles(refs: refs)
            preparedURLs = urls

            preparedURLs = urls
            lastExportCount = urls.count

            for item in batch.items {
                item.hasBeenStripped = true
            }

            #if os(iOS)
            isPresentingShareSheet = true
            #elseif os(macOS)
            let exportFolder = try await ExportFolderPicker.pickFolder()
            let writtenFolder = try StrippedFileExporter.exportFiles(urls, to: exportFolder)
            exportedFolderURL = writtenFolder
            isShowingMacExportDone = true
            #endif

        } catch {
            #if os(macOS)
            if (error as? ExportFolderPickerError) == .canceled {
                // user canceled folder selection — no alert
            } else {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isShowingError = true
            }
            #else
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
            #endif
        }
    }


    @MainActor
    private func persistBatch(from imported: [ImportedPhoto]) async {
        do {
            let source = imported.first?.source
            let drafts = try await processor.process(imported)

            let batch = PhotoAuditBatch(
                title: "New Album",
                source: source
            )

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
