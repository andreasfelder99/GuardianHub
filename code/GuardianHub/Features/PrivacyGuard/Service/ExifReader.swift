//
//  ExifReader.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import ImageIO

enum ExifReaderError: LocalizedError {
    case invalidImageData
    case noProperties

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The selected file could not be decoded as an image."
        case .noProperties:
            return "No metadata properties were found for this image."
        }
    }
}

struct ExifReader: Sendable {
    func read(from data: Data) throws -> ExifSummary {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ExifReaderError.invalidImageData
        }

        guard let raw = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            throw ExifReaderError.noProperties
        }

        let tiff = raw[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let exif = raw[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let gps = raw[kCGImagePropertyGPSDictionary] as? [CFString: Any]

        let hasAnyMetadata = (tiff != nil) || (exif != nil) || (gps != nil)

        let make = stringValue(from: tiff, key: kCGImagePropertyTIFFMake)
        let model = stringValue(from: tiff, key: kCGImagePropertyTIFFModel)

        let (lat, lon) = parseGPS(from: gps)

        return ExifSummary(
            hasExif: hasAnyMetadata,
            hasGPS: lat != nil && lon != nil,
            latitude: lat,
            longitude: lon,
            cameraMake: make,
            cameraModel: model
        )
    }

    private func parseGPS(from gps: [CFString: Any]?) -> (Double?, Double?) {
        guard let gps else { return (nil, nil) }

        let latValue = doubleValue(from: gps, key: kCGImagePropertyGPSLatitude)
        let lonValue = doubleValue(from: gps, key: kCGImagePropertyGPSLongitude)

        guard var lat = latValue, var lon = lonValue else {
            return (nil, nil)
        }

        let latRef = stringValue(from: gps, key: kCGImagePropertyGPSLatitudeRef)
        let lonRef = stringValue(from: gps, key: kCGImagePropertyGPSLongitudeRef)

        if latRef?.uppercased() == "S" { lat = -abs(lat) }
        if latRef?.uppercased() == "N" { lat = abs(lat) }

        if lonRef?.uppercased() == "W" { lon = -abs(lon) }
        if lonRef?.uppercased() == "E" { lon = abs(lon) }

        return (lat, lon)
    }

    private func stringValue(from dict: [CFString: Any]?, key: CFString) -> String? {
        guard let dict else { return nil }
        if let s = dict[key] as? String { return s }
        if let n = dict[key] as? NSNumber { return n.stringValue }
        return nil
    }

    private func doubleValue(from dict: [CFString: Any]?, key: CFString) -> Double? {
        guard let dict else { return nil }
        if let d = dict[key] as? Double { return d }
        if let n = dict[key] as? NSNumber { return n.doubleValue }
        if let s = dict[key] as? String, let d = Double(s) { return d }
        return nil
    }
}
