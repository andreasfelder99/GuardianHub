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

    // newest first
    @Query(sort: \PhotoAudit.createdAt, order: .reverse)
    private var audits: [PhotoAudit]

    var body: some View {
        Group {
            if audits.isEmpty {
                ContentUnavailableView(
                    "No Photo Audits",
                    systemImage: "shield.lefthalf.filled",
                    description: Text("Import a photo to inspect EXIF metadata and location data.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(audits) { audit in
                            NavigationLink {
                                PhotoAuditDetailView(audit: audit)
                            } label: {
                                PhotoAuditRow(audit: audit)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(audit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
        }
        .navigationTitle("Privacy Guard")
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(audits[index])
        }
    }
}
