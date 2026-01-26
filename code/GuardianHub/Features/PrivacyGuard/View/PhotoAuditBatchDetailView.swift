//
//  PhotoAuditBatchDetailView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PhotoAuditBatchDetailView: View {
    let batch: PhotoAuditBatch

    @State private var selectedItemID: PersistentIdentifier?

    // Centralized export/share workflow (@Observable)
    @State private var exportWorkflow = StrippedExportWorkflow()

    // Rename state
    @State private var isPresentingRename = false
    @State private var draftTitle = ""

    // iOS “prepared” notice after share sheet dismiss
    @State private var isShowingPreparedNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                thumbnailCarousel

                Divider()

                if let selected = selectedItem {
                    PhotoAuditItemMetadataPanel(
                        item: selected,
                        onExportSelected: {
                            Task { await exportWorkflow.runExport(for: [selected]) }
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "No Selection",
                        systemImage: "hand.point.up.left",
                        description: Text("Select a photo to view its metadata.")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle(batch.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await exportWorkflow.runExport(for: batch.items) }
                } label: {
                    if exportWorkflow.isRunning {
                        Label("Preparing…", systemImage: "hourglass")
                    } else {
                        #if os(macOS)
                        Label("Export Stripped", systemImage: "square.and.arrow.down")
                        #else
                        Label("Share Stripped", systemImage: "square.and.arrow.up")
                        #endif
                    }
                }
                .disabled(exportWorkflow.isRunning || batch.items.isEmpty)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftTitle = batch.title
                    isPresentingRename = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
        }
        // Export workflow error alert
        .alert("Export Error", isPresented: $exportWorkflow.isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportWorkflow.errorMessage ?? "Unknown error")
        }
        // Rename alert
        .alert("Rename Album", isPresented: $isPresentingRename) {
            TextField("Album name", text: $draftTitle)
            Button("Save") {
                let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { batch.title = trimmed }
            }
            Button("Cancel", role: .cancel) { }
        }

        #if os(iOS)
        // iOS share sheet for album/selected export
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

        .onAppear {
            if selectedItemID == nil {
                selectedItemID = batch.items.first?.persistentModelID
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(batch.items.count) photo(s)")
                .font(.headline)

            if let source = batch.source {
                Text("Source: \(source)")
                    .foregroundStyle(.secondary)
            }

            if exportWorkflow.isRunning {
                ProgressView()
                    .padding(.top, 6)
            }
        }
    }

    private var thumbnailCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(batch.items) { item in
                    ThumbnailCell(
                        item: item,
                        isSelected: item.persistentModelID == selectedItemID
                    )
                    .onTapGesture {
                        selectedItemID = item.persistentModelID
                    }
                    .accessibilityAddTraits(item.persistentModelID == selectedItemID ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var selectedItem: PhotoAuditItem? {
        guard let selectedItemID else { return nil }
        return batch.items.first(where: { $0.persistentModelID == selectedItemID })
    }
}
