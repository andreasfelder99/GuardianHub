import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                // summary tile that shows identity check stats
                IdentityCheckSummaryTile(
                    onOpen: { navModel.selectedSection = .identityCheck }
                )
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Dashboard")
    }

    // header section with title and description
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Security Overview")
                .font(.title2.weight(.semibold))
            Text("Review recent checks and jump into tools.")
                .foregroundStyle(.secondary)
        }
    }
}
