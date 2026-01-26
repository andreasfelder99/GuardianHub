//
//  OriginalPhotoLoader+iOS.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

#if os(iOS)

import Foundation
import Photos

nonisolated struct IOSOriginalPhotoLoader: OriginalPhotoLoading {
    func loadOriginalData(for ref: PhotoItemReference) async throws -> Data {
        guard let id = ref.assetIdentifier, !id.isEmpty else {
            throw OriginalPhotoLoaderError.missingReference
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = assets.firstObject else {
            throw OriginalPhotoLoaderError.cannotReadFile
        }

        return try await requestImageData(for: asset)
    }

    private func requestImageData(for asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .current

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? NSError {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data else {
                    continuation.resume(throwing: OriginalPhotoLoaderError.cannotReadFile)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
}

#endif
