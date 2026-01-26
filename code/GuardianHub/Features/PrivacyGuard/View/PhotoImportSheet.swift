//
//  PhotoImportSheet.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import PhotosUI
#endif

struct PhotoImportSheet: View {
    let onImported: ([ImportedPhoto]) -> Void
    let onCancel: () -> Void

    @State private var errorMessage: String?
    @State private var isShowingError = false

    #if os(iOS)
    @State private var selectedItems: [PhotosPickerItem] = []
    #endif

    #if os(macOS)
    @State private var isPresentingFileImporter = false
    #endif

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select one or more images to audit metadata. Photos are processed locally.")
                    .foregroundStyle(.secondary)

                #if os(iOS)
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 0, // 0 = unlimited
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photos", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: selectedItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    Task { await importFromPhotosPicker(newItems) }
                }
                #endif

                #if os(macOS)
                Button {
                    isPresentingFileImporter = true
                } label: {
                    Label("Choose Files", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .fileImporter(
                    isPresented: $isPresentingFileImporter,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard !urls.isEmpty else { return }
                        Task { await importFromFileURLs(urls) }
                    case .failure(let error):
                        presentError("Import failed: \(error.localizedDescription)")
                    }
                }
                #endif

                Spacer()
            }
            .padding()
            .navigationTitle("Import Photos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .alert("Import Error", isPresented: $isShowingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    #if os(iOS)
    private func importFromPhotosPicker(_ items: [PhotosPickerItem]) async {
        do {
            let imported: [ImportedPhoto] = try await withThrowingTaskGroup(of: ImportedPhoto?.self) { group in
                for item in items {
                    group.addTask {
                        let data = try await item.loadTransferable(type: Data.self)
                        guard let data else { return nil }

                        // Best-effort: itemIdentifier is available on PhotosPickerItem on modern iOS
                        let assetId = item.itemIdentifier

                        return ImportedPhoto(
                            data: data,
                            filename: nil,
                            source: "PhotosPicker",
                            assetIdentifier: assetId,
                            fileBookmark: nil
                        )
                    }
                }

                var results: [ImportedPhoto] = []
                for try await r in group {
                    if let r { results.append(r) }
                }
                return results
            }

            guard !imported.isEmpty else {
                presentError("Could not load the selected photos.")
                return
            }

            await MainActor.run {
                onImported(imported)
            }
        } catch {
            presentError("Could not load photos: \(error.localizedDescription)")
        }
    }
    #endif

    #if os(macOS)
    private func importFromFileURLs(_ urls: [URL]) async {
        do {
            var imported: [ImportedPhoto] = []
            imported.reserveCapacity(urls.count)

            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    presentError("Permission denied for \(url.lastPathComponent).")
                    return
                }
                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                // Create bookmark while access is active
                let bookmark = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )

                // Read file while access is active
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }

                let data = try handle.readToEnd() ?? Data()

                imported.append(
                    ImportedPhoto(
                        data: data,
                        filename: url.lastPathComponent,
                        source: "FileImporter",
                        assetIdentifier: nil,
                        fileBookmark: bookmark
                    )
                )
            }

            guard !imported.isEmpty else {
                presentError("No files could be imported.")
                return
            }

            await MainActor.run {
                onImported(imported)
            }
        } catch {
            presentError("Could not read file(s): \(error.localizedDescription)")
        }
    }
    #endif

    @MainActor
    private func presentError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
