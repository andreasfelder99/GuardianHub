//
//  PhotoAuditProcessor.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

actor PhotoAuditProcessor {

    func process(_ imported: [ImportedPhoto]) throws -> [PhotoAuditItemDraft] {
        var drafts: [PhotoAuditItemDraft] = []
        drafts.reserveCapacity(imported.count)

        for photo in imported {
            let summary = try readExifSummary(from: photo.data)
            let thumb = try makeThumbnailJPEG(from: photo.data, maxPixelSize: 320, compressionQuality: 0.75)

            drafts.append(
                PhotoAuditItemDraft(
                    originalFilename: photo.filename,
                    hasExif: summary.hasExif,
                    hasGPS: summary.hasGPS,
                    latitude: summary.latitude,
                    longitude: summary.longitude,
                    cameraMake: summary.cameraMake,
                    cameraModel: summary.cameraModel,
                    thumbnailJPEG: thumb,
                    assetIdentifier: photo.assetIdentifier,
                    fileBookmark: photo.fileBookmark
                )
            )
        }

        return drafts
    }

    // MARK: - EXIF

    private func readExifSummary(from data: Data) throws -> ExifSummary {
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

    // MARK: - Thumbnail

    private func makeThumbnailJPEG(from data: Data, maxPixelSize: Int, compressionQuality: Double) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ThumbnailGeneratorError.invalidImageData
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ThumbnailGeneratorError.couldNotCreateThumbnail
        }

        let outData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outData as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ThumbnailGeneratorError.couldNotEncodeJPEG
        }

        let destOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        CGImageDestinationAddImage(destination, cgThumb, destOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ThumbnailGeneratorError.couldNotEncodeJPEG
        }

        return outData as Data
    }
}
