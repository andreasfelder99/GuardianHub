#if os(macOS)

import Foundation
import AppKit

enum StrippedFileExporterError: LocalizedError {
    case noFiles

    var errorDescription: String? {
        switch self {
        case .noFiles:
            return "No stripped files were generated."
        }
    }
}

struct StrippedFileExporter {
    static func exportFiles(_ urls: [URL], to folder: URL) throws -> URL {
        guard !urls.isEmpty else { throw StrippedFileExporterError.noFiles }

        let fm = FileManager.default

        // Create a subfolder so repeated exports don't overwrite silently
        let exportDir = folder.appendingPathComponent("GuardianHub-Stripped-\(timestamp())", isDirectory: true)
        try fm.createDirectory(at: exportDir, withIntermediateDirectories: true)

        for src in urls {
            let dest = exportDir.appendingPathComponent(src.lastPathComponent)
            // If exists, overwrite (rare due to timestamp folder)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: src, to: dest)
        }

        return exportDir
    }

    static func revealInFinder(_ folder: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HH:mm"
        return formatter.string(from: .now)
    }
}

#endif
