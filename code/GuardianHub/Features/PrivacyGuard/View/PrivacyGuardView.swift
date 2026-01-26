//
//  PrivacyGuardView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI
import SwiftData

struct PrivacyGuardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PhotoAuditBatch.createdAt, order: .reverse)
    private var batches: [PhotoAuditBatch]

    @State private var isPresentingImportSheet = false

    var body: some View {
        Group {
            if batches.isEmpty {
                ContentUnavailableView(
                    "No Photo Albums",
                    systemImage: "photo.badge.shield.checkmark",
                    description: Text("Import one or more photos to inspect EXIF metadata and location data.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    Button {
                        isPresentingImportSheet = true
                    } label: {
                        Label("Import Photos", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: 320)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                List {
                    Section {
                        ForEach(batches) { batch in
                            NavigationLink {
                                PhotoAuditBatchDetailView(batch: batch)
                            } label: {
                                PhotoAuditBatchRow(batch: batch)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(batch)
                                } label: {
                                    Label("Delete Album", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
        }
        .navigationTitle("Privacy Guard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $isPresentingImportSheet) {
            PhotoImportSheet(
                onImported: { _ in
                    isPresentingImportSheet = false
                },
                onCancel: {
                    isPresentingImportSheet = false
                }
            )
        }
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(batches[index])
        }
    }
}
