//
//  PlatformImage.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias NativeImage = UIImage
#elseif os(macOS)
import AppKit
typealias NativeImage = NSImage
#endif

struct PlatformImage {
    let native: NativeImage

    init?(jpegData: Data) {
        #if os(iOS)
        guard let img = UIImage(data: jpegData) else { return nil }
        self.native = img
        #elseif os(macOS)
        guard let img = NSImage(data: jpegData) else { return nil }
        self.native = img
        #endif
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage.native)
        #elseif os(macOS)
        self.init(nsImage: platformImage.native)
        #endif
    }
}
