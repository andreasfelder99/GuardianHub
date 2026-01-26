//
//  ThumbnailGenerator.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ThumbnailGeneratorError: LocalizedError {
    case invalidImageData
    case couldNotCreateThumbnail
    case couldNotEncodeJPEG

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The selected file could not be decoded as an image."
        case .couldNotCreateThumbnail:
            return "Could not generate a thumbnail for this image."
        case .couldNotEncodeJPEG:
            return "Could not encode the thumbnail as JPEG."
        }
    }
}

struct ThumbnailGenerator: Sendable {
    /// Creates a JPEG thumbnail with max pixel size (long edge) around 300 by default.
    func makeThumbnailJPEG(from data: Data, maxPixelSize: Int = 320, compressionQuality: Double = 0.75) throws -> Data {
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
        guard let destination = CGImageDestinationCreateWithData(outData as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
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
