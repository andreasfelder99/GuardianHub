//
//  StrippedExportWorkflow.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class StrippedExportWorkflow {

    var isRunning: Bool = false

    // Prepared URLs (iOS share sheet uses these)
    var preparedURLs: [URL] = []

    // macOS export destination folder created by exporter (subfolder)
    var exportedFolderURL: URL?

    // Last prepared count for feedback
    var lastPreparedCount: Int?

    // Errors for alerting
    var errorMessage: String?
    var isShowingError: Bool = false

    // iOS share sheet presentation
    var isPresentingShareSheet: Bool = false

    // macOS completion alert
    var isShowingMacExportDone: Bool = false

    private let coordinator = StrippedExportCoordinator()

    func runExport(for items: [PhotoAuditItem]) async {
        guard !items.isEmpty else { return }

        isRunning = true
        defer { isRunning = false }

        preparedURLs = []
        exportedFolderURL = nil
        lastPreparedCount = nil

        do {
            #if os(iOS)
            try await PhotosAuthorization.ensureAuthorized()
            #endif

            let refs = coordinator.refs(for: items)
            let urls = try await coordinator.prepareStrippedFiles(refs: refs)

            preparedURLs = urls
            lastPreparedCount = urls.count

            // Mark unique stripping
            for item in items {
                item.hasBeenStripped = true
            }

            #if os(iOS)
            isPresentingShareSheet = true
            #elseif os(macOS)
            let exportFolder = try await ExportFolderPicker.pickFolder()
            let writtenFolder = try StrippedFileExporter.exportFiles(urls, to: exportFolder)
            exportedFolderURL = writtenFolder
            isShowingMacExportDone = true
            #endif

        } catch {
            #if os(macOS)
            if (error as? ExportFolderPickerError) == .canceled {
                return
            }
            #endif
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isShowingError = true
        }
    }
}
