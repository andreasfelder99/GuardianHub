//
//  OriginalPhotoLoading.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

/// A Sendable reference to reload an original image without storing full-size image data in SwiftData.
struct PhotoItemReference: Sendable {
    let filename: String?
    let assetIdentifier: String?
    let fileBookmark: Data?
}

protocol OriginalPhotoLoading: Sendable {
    func loadOriginalData(for ref: PhotoItemReference) async throws -> Data
}

enum OriginalPhotoLoaderError: LocalizedError {
    case missingReference
    case cannotAccessFile
    case cannotReadFile
    case unsupported

    var errorDescription: String? {
        switch self {
        case .missingReference:
            return "This photo cannot be reloaded because its source reference is missing."
        case .cannotAccessFile:
            return "The selected file cannot be accessed. Please re-import the photos."
        case .cannotReadFile:
            return "The selected file could not be read."
        case .unsupported:
            return "This source type is not supported on the current platform."
        }
    }
}
