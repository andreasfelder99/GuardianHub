//
//  PhotoAuditItem.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import SwiftData

@Model
final class PhotoAuditItem {
    // Parent relationship
    var batch: PhotoAuditBatch?

    var createdAt: Date
    var originalFilename: String?

    var hasExif: Bool
    var hasGPS: Bool
    var latitude: Double?
    var longitude: Double?

    var cameraMake: String?
    var cameraModel: String?

    var thumbnailJPEG: Data?

    var assetIdentifier: String?

    var fileBookmark: Data?

    var hasBeenStripped: Bool

    init(
        originalFilename: String? = nil,
        hasExif: Bool,
        hasGPS: Bool,
        latitude: Double? = nil,
        longitude: Double? = nil,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        thumbnailJPEG: Data? = nil,
        assetIdentifier: String? = nil,
        fileBookmark: Data? = nil,
        createdAt: Date = .now,
        hasBeenStripped: Bool = false
    ) {
        self.batch = nil
        self.createdAt = createdAt
        self.originalFilename = originalFilename
        self.hasExif = hasExif
        self.hasGPS = hasGPS
        self.latitude = latitude
        self.longitude = longitude
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.thumbnailJPEG = thumbnailJPEG
        self.assetIdentifier = assetIdentifier
        self.fileBookmark = fileBookmark
        self.hasBeenStripped = hasBeenStripped
    }
}
