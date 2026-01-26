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

    @State private var isPreparingExport = false
    @State private var preparedURLs: [URL] = []

    @State private var errorMessage: String?
    @State private var isShowingError = false

    // iOS share sheet
    @State private var isPresentingShareSheet = false

    // macOS export confirmation
    @State private var isShowingMacExportDone = false
    @State private var exportedFolderURL: URL?

    // Rename state
    @State private var isPresentingRename = false
    @State private var draftTitle = ""

    @State private var lastExportCount: Int?
    @State private var isShowingPreparedNotice = false

    private let coordinator = StrippedExportCoordinator()

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
                            Task { await exportSelectedPhoto(selected) }
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
                    Task { await exportWholeAlbum() }
                } label: {
                    if isPreparingExport {
                        Label("Preparing…", systemImage: "hourglass")
                    } else {
                        #if os(macOS)
                        Label("Export Stripped", systemImage: "square.and.arrow.down")
                        #else
                        Label("Share Stripped", systemImage: "square.and.arrow.up")
                        #endif
                    }
                }
                .disabled(isPreparingExport || batch.items.isEmpty)
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
        .alert("Privacy Guard Error", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .alert("Rename Album", isPresented: $isPresentingRename) {
            TextField("Album name", text: $draftTitle)
            Button("Save") {
                let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { batch.title = trimmed }
            }
            Button("Cancel", role: .cancel) { }
        }
        #if os(iOS)
        .sheet(isPresented: $isPresentingShareSheet, onDismiss: {
            if let lastExportCount {
                isShowingPreparedNotice = true
            }
        }) {
            ShareSheet(activityItems: preparedURLs)
        }
        #endif
        #if os(macOS)
        .alert("Export Complete", isPresented: $isShowingMacExportDone) {
            Button("Reveal in Finder") {
                if let url = exportedFolderURL {
                    StrippedFileExporter.revealInFinder(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Exported \(lastExportCount ?? 0) stripped photo(s) to:\n\(exportedFolderURL?.path ?? "")")
        }
        .alert("Stripped Copies Ready", isPresented: $isShowingPreparedNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            if let lastExportCount {
                Text("Prepared \(lastExportCount) stripped photo(s). Originals were not modified.")
            } else {
                Text("Prepared stripped photo(s). Originals were not modified.")
            }
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

            if isPreparingExport {
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

    @MainActor
    private func exportWholeAlbum() async {
        await exportItems(batch.items)
    }

    @MainActor
    private func exportSelectedPhoto(_ item: PhotoAuditItem) async {
        await exportItems([item])
    }

    @MainActor
    private func exportItems(_ items: [PhotoAuditItem]) async {
        isPreparingExport = true
        preparedURLs = []
        exportedFolderURL = nil

        do {
            #if os(iOS)
            try await PhotosAuthorization.ensureAuthorized()
            #endif

            let refs = coordinator.refs(for: items)
            let urls = try await coordinator.prepareStrippedFiles(refs: refs)
            preparedURLs = urls
            lastExportCount = urls.count

            for item in items {
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
                // user canceled export folder selection
            } else {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isShowingError = true
            }
            #else
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
            #endif
        }

        isPreparingExport = false
    }
}
