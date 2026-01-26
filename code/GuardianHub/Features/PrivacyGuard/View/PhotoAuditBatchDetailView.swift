//
//  PhotoAuditBatchDetailView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PhotoAuditBatchDetailView: View {
    let batch: PhotoAuditBatch

    @State private var selectedItemID: PersistentIdentifier?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                thumbnailGrid

                Divider()

                metadataPanel
            }
            .padding()
        }
        .navigationTitle("Album")
        .onAppear {
            if selectedItemID == nil {
                selectedItemID = batch.items.first?.persistentModelID
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(batch.items.count) photo(s)")
                .font(.headline)

            if let source = batch.source {
                Text("Source: \(source)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 90, maximum: 160), spacing: 10, alignment: .top)
        ]
    }

    private var thumbnailGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(batch.items) { item in
                ThumbnailCell(
                    item: item,
                    isSelected: item.persistentModelID == selectedItemID
                )
                .onTapGesture {
                    selectedItemID = item.persistentModelID
                }
                .accessibilityAddTraits(item.persistentModelID == selectedItemID ? .isSelected : [])
            }
        }
    }

    @ViewBuilder
    private var metadataPanel: some View {
        if let selected = selectedItem {
            PhotoAuditItemMetadataPanel(item: selected)
        } else {
            ContentUnavailableView(
                "No Selection",
                systemImage: "hand.point.up.left",
                description: Text("Select a photo to view its metadata.")
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var selectedItem: PhotoAuditItem? {
        guard let selectedItemID else { return nil }
        return batch.items.first(where: { $0.persistentModelID == selectedItemID })
    }
}
