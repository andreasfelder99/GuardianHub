//
//  OriginalPhotoLoader+macOS.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

#if os(macOS)

import Foundation

nonisolated struct MacOriginalPhotoLoader: OriginalPhotoLoading {
    func loadOriginalData(for ref: PhotoItemReference) async throws -> Data {
        guard let bookmark = ref.fileBookmark else {
            throw OriginalPhotoLoaderError.missingReference
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        guard url.startAccessingSecurityScopedResource() else {
            throw OriginalPhotoLoaderError.cannotAccessFile
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            return try handle.readToEnd() ?? Data()
        } catch {
            throw OriginalPhotoLoaderError.cannotReadFile
        }
    }
}

#endif
