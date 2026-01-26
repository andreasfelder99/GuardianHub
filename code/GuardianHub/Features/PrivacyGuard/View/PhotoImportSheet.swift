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
    let onImported: (ImportedPhoto) -> Void
    let onCancel: () -> Void

    @State private var errorMessage: String?
    @State private var isShowingError = false

    #if os(iOS)
    @State private var selectedItem: PhotosPickerItem?
    #endif

    #if os(macOS)
    @State private var isPresentingFileImporter = false
    #endif

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select an image to audit its metadata. The photo is processed locally.")
                    .foregroundStyle(.secondary)

                #if os(iOS)
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .onChange(of: selectedItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        await importFromPhotosPicker(newItem)
                    }
                }
                #endif

                #if os(macOS)
                Button {
                    isPresentingFileImporter = true
                } label: {
                    Label("Choose File", systemImage: "doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .fileImporter(
                    isPresented: $isPresentingFileImporter,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        Task {
                            await importFromFileURL(url)
                        }
                    case .failure(let error):
                        presentError("Import failed: \(error.localizedDescription)")
                    }
                }
                #endif

                Spacer()
            }
            .padding()
            .navigationTitle("Import Photo")
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
    private func importFromPhotosPicker(_ item: PhotosPickerItem) async {
        do {
            // Data is sufficient for EXIF parsing later (ImageIO)
            guard let data = try await item.loadTransferable(type: Data.self) else {
                presentError("Could not load the selected image.")
                return
            }

            // PhotosPicker does not reliably expose the original filename
            let imported = ImportedPhoto(
                data: data,
                filename: nil,
                source: "PhotosPicker"
            )

            await MainActor.run {
                onImported(imported)
            }
        } catch {
            presentError("Could not load image: \(error.localizedDescription)")
        }
    }
    #endif

    #if os(macOS)
    private func importFromFileURL(_ url: URL) async {
        do {
            // Security-scoped access for sandboxed macOS apps
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer {
                if needsAccess { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url)
            let imported = ImportedPhoto(
                data: data,
                filename: url.lastPathComponent,
                source: "FileImporter"
            )

            await MainActor.run {
                onImported(imported)
            }
        } catch {
            presentError("Could not read file: \(error.localizedDescription)")
        }
    }
    #endif

    @MainActor
    private func presentError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
