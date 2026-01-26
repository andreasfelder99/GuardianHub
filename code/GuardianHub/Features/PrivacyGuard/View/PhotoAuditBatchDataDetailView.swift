//
//  PhotoAuditBatchDetailView.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct PhotoAuditBatchDetailView: View {
    let batch: PhotoAuditBatch

    var body: some View {
        List {
            Section("Photos") {
                ForEach(batch.items) { item in
                    NavigationLink {
                        PhotoAuditItemDetailView(item: item)
                    } label: {
                        PhotoAuditItemRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("Album")
    }
}
