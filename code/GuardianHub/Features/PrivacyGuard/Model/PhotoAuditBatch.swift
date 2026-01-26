//
//  PhotoAuditBatch.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation
import SwiftData

@Model
final class PhotoAuditBatch {
    var createdAt: Date

    var title: String

    var source: String?

    // A batch contains multiple photos
    @Relationship(deleteRule: .cascade, inverse: \PhotoAuditItem.batch)
    var items: [PhotoAuditItem]

    init(
        title: String = "Album (PhotosPicker)",
        source: String? = nil,
        createdAt: Date = .now
    ) {
        self.createdAt = createdAt
        self.title = title
        self.source = source
        self.items = []
    }
}
