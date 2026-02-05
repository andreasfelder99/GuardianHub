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

    // Import/persistence errors
    @State private var errorMessage: String?
    @State private var isShowingError = false

    // Rename state (context menu)
    @State private var isPresentingRename = false
    @State private var renameDraftTitle = ""
    @State private var batchToRename: PhotoAuditBatch?

    // Centralized export/share workflow (@Observable)
    @State private var exportWorkflow = StrippedExportWorkflow()

    // iOS “prepared” notice after share sheet dismiss
    @State private var isShowingPreparedNotice = false

    // Background processor (actor) for EXIF + thumbnail generation
    private let processor = PhotoAuditProcessor()
    
    private let sectionGradient = GuardianTheme.SectionColor.privacyGuard.gradient

    var body: some View {
        Group {
            if batches.isEmpty {
                emptyStateView
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
                                    Task { await exportWorkflow.runExport(for: batch.items) }
                                } label: {
                                    #if os(macOS)
                                    Label("Export Stripped", systemImage: "square.and.arrow.down")
                                    #else
                                    Label("Share Stripped", systemImage: "square.and.arrow.up")
                                    #endif
                                }
                                .disabled(exportWorkflow.isRunning || batch.items.isEmpty)

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
        #if os(macOS)
        .frame(minWidth: 400)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .tint(GuardianTheme.SectionColor.privacyGuard.primaryColor)
            }

            // Export progress indicator
            ToolbarItem(placement: .status) {
                if exportWorkflow.isRunning {
                    ProgressView()
                }
            }
        }
        .sheet(isPresented: $isPresentingImportSheet) {
            PhotoImportSheet(
                onImported: { imported in
                    isPresentingImportSheet = false
                    Task { await persistBatch(from: imported) }
                },
                onCancel: {
                    isPresentingImportSheet = false
                }
            )
        }

        // Rename alert
        .alert("Rename Album", isPresented: $isPresentingRename) {
            TextField("Album name", text: $renameDraftTitle)

            Button("Save") { saveRename() }

            Button("Cancel", role: .cancel) {
                batchToRename = nil
            }
        }

        // Import/persistence error alert
        .alert("Privacy Guard Error", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }

        // Export workflow error alert
        .alert("Export Error", isPresented: $exportWorkflow.isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportWorkflow.errorMessage ?? "Unknown error")
        }

        #if os(iOS)
        // iOS share sheet for list-level export
        .sheet(isPresented: $exportWorkflow.isPresentingShareSheet) {
            ShareSheet(activityItems: exportWorkflow.preparedURLs) { completed in
                if completed, exportWorkflow.lastPreparedCount != nil {
                    isShowingPreparedNotice = true
                }
            }
        }
        .alert("Stripped Copies Ready", isPresented: $isShowingPreparedNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            let c = exportWorkflow.lastPreparedCount ?? 0
            Text("Prepared \(c) stripped photo(s). Originals were not modified.")
        }
        #endif

        #if os(macOS)
        // macOS export confirmation
        .alert("Export Complete", isPresented: $exportWorkflow.isShowingMacExportDone) {
            Button("Reveal in Finder") {
                if let url = exportWorkflow.exportedFolderURL {
                    StrippedFileExporter.revealInFinder(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            let c = exportWorkflow.lastPreparedCount ?? 0
            Text("Exported \(c) stripped photo(s) to:\n\(exportWorkflow.exportedFolderURL?.path ?? "")")
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(sectionGradient.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(sectionGradient)
            }
            
            VStack(spacing: 8) {
                Text("No Photo Albums")
                    .font(.title2.weight(.bold))
                
                Text("Import one or more photos to inspect EXIF metadata and location data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                isPresentingImportSheet = true
            } label: {
                Label("Import Photos", systemImage: "square.and.arrow.down")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(GuardianTheme.SectionColor.privacyGuard.primaryColor)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
