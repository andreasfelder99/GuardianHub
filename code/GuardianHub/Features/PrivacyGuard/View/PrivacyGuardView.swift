import SwiftUI

struct PrivacyGuardView: View {
    var body: some View {
        ContentUnavailableView(
            "Privacy Guard",
            systemImage: "photo.badge.shield.checkmark",
            description: Text("Audit photo metadata and remove sensitive EXIF data.")
        )
        .navigationTitle("Privacy Guard")
    }
}
