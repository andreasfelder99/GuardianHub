//
//  PhotoAuditItemDraft.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

struct PhotoAuditItemDraft: Sendable {
    let originalFilename: String?
    let hasExif: Bool
    let hasGPS: Bool
    let latitude: Double?
    let longitude: Double?
    let cameraMake: String?
    let cameraModel: String?
    let thumbnailJPEG: Data?
    let assetIdentifier: String?
    let fileBookmark: Data?
}
