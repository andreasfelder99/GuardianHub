//
//  ExifSummary.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

struct ExifSummary: Sendable {
    let hasExif: Bool
    let hasGPS: Bool
    let latitude: Double?
    let longitude: Double?
    let cameraMake: String?
    let cameraModel: String?

    static let empty = ExifSummary(
        hasExif: false,
        hasGPS: false,
        latitude: nil,
        longitude: nil,
        cameraMake: nil,
        cameraModel: nil
    )
}
