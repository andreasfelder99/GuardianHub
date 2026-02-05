import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeader

                // summary tile that shows identity check stats
                IdentityCheckSummaryTile(
                    onOpen: { navModel.selectedSection = .identityCheck }
                )

                WebAuditorSummaryTile(
                    onOpen: { navModel.selectedSection = .webAuditor }
                )

                PrivacyGuardSummaryTile(
                    onOpen: { navModel.selectedSection = .privacyGuard }
                )

                PasswordLabSummaryTile(
                    onOpen: { navModel.selectedSection = .passwordLab }
                )
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Dashboard")
        #if os(macOS)
        .frame(minWidth: 400)
        #endif
    }

    // Enhanced hero header with gradient accent
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(GuardianTheme.SectionColor.dashboard.gradient)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Overview")
                        .font(.title2.weight(.bold))
                    
                    Text("Review recent checks and jump into tools.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
