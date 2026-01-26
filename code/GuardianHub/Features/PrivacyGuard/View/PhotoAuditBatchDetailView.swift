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

    // Rename state
    @State private var isPresentingRename = false
    @State private var draftTitle = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                thumbnailCarousel

                Divider()

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
            .padding()
        }
        .navigationTitle(batch.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draftTitle = batch.title
                    isPresentingRename = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
        }
        .alert("Rename Album", isPresented: $isPresentingRename) {
            TextField("Album name", text: $draftTitle)

            Button("Save") {
                let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    batch.title = trimmed
                }
            }

            Button("Cancel", role: .cancel) { }
        }
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

    private var thumbnailCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
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
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var selectedItem: PhotoAuditItem? {
        guard let selectedItemID else { return nil }
        return batch.items.first(where: { $0.persistentModelID == selectedItemID })
    }
}
