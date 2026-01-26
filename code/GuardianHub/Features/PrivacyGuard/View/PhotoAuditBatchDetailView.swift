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

    @State private var isPreparingShare = false
    @State private var shareURLs: [URL] = []

    @State private var errorMessage: String?
    @State private var isShowingError = false

    // iOS share sheet
    @State private var isPresentingShareSheet = false

    // macOS export confirmation
    @State private var isShowingMacExportDone = false
    @State private var exportedFolderURL: URL?

    private let preparer = StrippedExportPreparer()

    // Rename state
    @State private var isPresentingRename = false
    @State private var draftTitle = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                thumbnailCarousel
                Divider()

                if let selected = selectedItem {
                    PhotoAuditItemMetadataPanel(item: selected)
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
                    Task { await shareStripped() }
                } label: {
                    if isPreparingShare {
                        Label("Preparing…", systemImage: "hourglass")
                    } else {
                        #if os(macOS)
                        Label("Export Stripped", systemImage: "square.and.arrow.down")
                        #else
                        Label("Share Stripped", systemImage: "square.and.arrow.up")
                        #endif
                    }
                }
                .disabled(isPreparingShare || batch.items.isEmpty)
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
        .sheet(isPresented: $isPresentingShareSheet) {
            ShareSheet(activityItems: shareURLs)
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
            Text(exportedFolderURL?.path ?? "Exported stripped images.")
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

            if isPreparingShare {
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
    private func shareStripped() async {
        isPreparingShare = true
        shareURLs = []
        exportedFolderURL = nil

        do {
            #if os(iOS)
            try await PhotosAuthorization.ensureAuthorized()
            #endif

            let loader: OriginalPhotoLoading
            #if os(iOS)
            loader = IOSOriginalPhotoLoader()
            #elseif os(macOS)
            loader = MacOriginalPhotoLoader()
            #else
            throw OriginalPhotoLoaderError.unsupported
            #endif

            let refs: [PhotoItemReference] = batch.items.map { item in
                PhotoItemReference(
                    filename: item.originalFilename,
                    assetIdentifier: item.assetIdentifier,
                    fileBookmark: item.fileBookmark
                )
            }

            // Prepare stripped files in temp dir
            let urls = try await preparer.prepareStrippedFiles(refs: refs, loader: loader)
            shareURLs = urls

            #if os(iOS)
            // Present share sheet immediately
            isPresentingShareSheet = true
            #elseif os(macOS)
            // Ask user for an export folder, then copy stripped files there
            let exportFolder = try await ExportFolderPicker.pickFolder()
            let writtenFolder = try StrippedFileExporter.exportFiles(urls, to: exportFolder)
            exportedFolderURL = writtenFolder
            isShowingMacExportDone = true
            #endif

        } catch {
            // ignore macOS cancel as a non-error UX
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

        isPreparingShare = false
    }
}
