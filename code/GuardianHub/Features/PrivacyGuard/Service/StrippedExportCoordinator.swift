//
//  StrippedExportCoordinator.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

struct StrippedExportCoordinator {
    private let preparer = StrippedExportPreparer()

    @MainActor
    func refs(for items: [PhotoAuditItem]) -> [PhotoItemReference] {
        items.map {
            PhotoItemReference(
                filename: $0.originalFilename,
                assetIdentifier: $0.assetIdentifier,
                fileBookmark: $0.fileBookmark
            )
        }
    }

    func prepareStrippedFiles(
        refs: [PhotoItemReference]
    ) async throws -> [URL] {

        let loader: OriginalPhotoLoading
        #if os(iOS)
        loader = IOSOriginalPhotoLoader()
        #elseif os(macOS)
        loader = MacOriginalPhotoLoader()
        #else
        throw OriginalPhotoLoaderError.unsupported
        #endif

        return try await preparer.prepareStrippedFiles(refs: refs, loader: loader)
    }
}
