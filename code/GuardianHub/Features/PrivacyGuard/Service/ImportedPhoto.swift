//
//  ImportedPhoto.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

struct ImportedPhoto: Sendable {
    let data: Data
    let filename: String?
    let source: String

    // iOS Photos: PHAsset local identifier
    let assetIdentifier: String?

    // macOS Files: security-scoped bookmark data
    let fileBookmark: Data?
}
