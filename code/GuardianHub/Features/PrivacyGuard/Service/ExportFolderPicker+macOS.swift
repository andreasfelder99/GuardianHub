#if os(macOS)

import Foundation
import AppKit

enum ExportFolderPickerError: LocalizedError {
    case canceled

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Export was canceled."
        }
    }
}

struct ExportFolderPicker {
    static func pickFolder() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = "Choose Export Folder"
            panel.prompt = "Export"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true

            panel.begin { response in
                guard response == .OK, let url = panel.url else {
                    continuation.resume(throwing: ExportFolderPickerError.canceled)
                    return
                }
                continuation.resume(returning: url)
            }
        }
    }
}

#endif
