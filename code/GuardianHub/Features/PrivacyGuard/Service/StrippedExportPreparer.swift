//
//  StrippedExportPreparer.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

actor StrippedExportPreparer {
    private let stripper = MetadataStripper()

    func prepareStrippedFiles(
        refs: [PhotoItemReference],
        loader: OriginalPhotoLoading
    ) async throws -> [URL] {

        let dir = try makeFreshTempDirectory()

        var out: [URL] = []
        out.reserveCapacity(refs.count)

        for (idx, ref) in refs.enumerated() {
            let original = try await loader.loadOriginalData(for: ref)
            let stripped = try stripper.stripMetadata(from: original)

            let base = sanitizedBaseName(from: ref.filename) ?? "Photo-\(idx + 1)"
            let filename = "\(base)-stripped.\(stripped.fileExtension)"
            let url = dir.appendingPathComponent(filename)

            try stripped.data.write(to: url, options: [.atomic])
            out.append(url)
        }

        return out
    }

    private func makeFreshTempDirectory() throws -> URL {
        let base = FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("GuardianHub-Stripped-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func sanitizedBaseName(from filename: String?) -> String? {
        guard let filename, !filename.isEmpty else { return nil }
        let name = (filename as NSString).deletingPathExtension
        return name.isEmpty ? nil : name
    }
}
