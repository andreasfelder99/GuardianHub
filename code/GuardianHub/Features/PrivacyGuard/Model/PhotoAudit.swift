//
//  PhotoAudit.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import SwiftData

@Model
final class PhotoAudit {
    var createdAt: Date

    var source: String?

    var originalFilename: String?

    // High-level flags
    var hasExif: Bool
    var hasGPS: Bool

    // GPS coordinates (if present)
    var latitude: Double?
    var longitude: Double?

    // Camera info (if present)
    var cameraMake: String?
    var cameraModel: String?

    init(
        source: String? = nil,
        originalFilename: String? = nil,
        hasExif: Bool,
        hasGPS: Bool,
        latitude: Double? = nil,
        longitude: Double? = nil,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        createdAt: Date = .now
    ) {
        self.createdAt = createdAt
        self.source = source
        self.originalFilename = originalFilename
        self.hasExif = hasExif
        self.hasGPS = hasGPS
        self.latitude = latitude
        self.longitude = longitude
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
    }
}
