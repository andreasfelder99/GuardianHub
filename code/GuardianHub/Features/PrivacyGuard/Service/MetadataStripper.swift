//
//  MetadataStripper.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum MetadataStripperError: LocalizedError {
    case invalidImage
    case cannotCreateOutput

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be decoded."
        case .cannotCreateOutput:
            return "The sanitized image could not be created."
        }
    }
}

nonisolated struct MetadataStripper: Sendable {
    /// Returns a re-encoded copy of the image with metadata removed.
    /// Orientation is baked in by generating a full-size transformed image.
    func stripMetadata(from data: Data) throws -> (data: Data, fileExtension: String) {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw MetadataStripperError.invalidImage
        }

        let type = CGImageSourceGetType(src) as String?
        let utType = type.flatMap { UTType($0) } ?? .jpeg

        // Determine max pixel size to preserve resolution as much as possible while baking orientation.
        let props = (CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]) ?? [:]
        let w = (props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let h = (props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        let maxPixel = max(w, h, 1)

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(src, 0, thumbOptions as CFDictionary) else {
            throw MetadataStripperError.invalidImage
        }

        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out as CFMutableData, utType.identifier as CFString, 1, nil) else {
            throw MetadataStripperError.cannotCreateOutput
        }

        // Add image without metadata dictionaries => strips EXIF/GPS/etc.
        CGImageDestinationAddImage(dest, cgImage, nil)

        guard CGImageDestinationFinalize(dest) else {
            throw MetadataStripperError.cannotCreateOutput
        }

        return (out as Data, preferredExtension(for: utType))
    }

    private func preferredExtension(for type: UTType) -> String {
        // Pick a stable extension for common image types.
        if type == .jpeg { return "jpg" }
        if type == .png { return "png" }
        if type.identifier == "public.heic" || type.identifier == "public.heif" { return "heic" }
        // Fallback
        return "img"
    }
}
