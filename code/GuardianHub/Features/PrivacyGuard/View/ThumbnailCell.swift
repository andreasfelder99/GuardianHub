//
//  ThumbnailCell.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import SwiftUI

struct ThumbnailCell: View {
    let item: PhotoAuditItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderStyle, lineWidth: isSelected ? 2 : 1)
                )

            Text(item.originalFilename ?? "Photo")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var borderStyle: AnyShapeStyle {
        isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = item.thumbnailJPEG, let image = PlatformImage(jpegData: data) {
            Image(platformImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.quaternary.opacity(0.35))
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
