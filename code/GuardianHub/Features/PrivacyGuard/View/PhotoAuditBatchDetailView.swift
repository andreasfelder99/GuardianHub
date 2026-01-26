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

    private let preparer = StrippedExportPreparer()

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
                if !shareURLs.isEmpty {
                    ShareLink(items: shareURLs) {
                        Label("Share Stripped", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        Task { await prepareShare() }
                    } label: {
                        if isPreparingShare {
                            Label("Preparing…", systemImage: "hourglass")
                        } else {
                            Label("Share Stripped", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isPreparingShare || batch.items.isEmpty)
                }
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
        .onAppear {
            if selectedItemID == nil {
                selectedItemID = batch.items.first?.persistentModelID
            }
        }
    }

    // Rename state (kept here because you already added rename in this view)
    @State private var isPresentingRename = false
    @State private var draftTitle = ""

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
    private func prepareShare() async {
        isPreparingShare = true
        shareURLs = [] // reset

        do {
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

            let urls = try await preparer.prepareStrippedFiles(refs: refs, loader: loader)
            shareURLs = urls
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
        }

        isPreparingShare = false
    }
}
