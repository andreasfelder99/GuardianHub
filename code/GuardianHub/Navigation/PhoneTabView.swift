import SwiftUI

/**
 * PhoneTabView is the view for the phone tab.
 * It is used to display the dashboard and identity check views in a tab view.
 */

#if os(iOS)
struct PhoneTabView: View {
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(AppSection.dashboard.title, systemImage: AppSection.dashboard.systemImage)
            }
            .tag(AppSection.dashboard)

            NavigationStack {
                IdentityCheckView()
            }
            .tabItem {
                Label(AppSection.identityCheck.title, systemImage: AppSection.identityCheck.systemImage)
            }
            .tag(AppSection.identityCheck)
        }
    }

    private var tabSelection: Binding<AppSection> {
        Binding(
            get: { navModel.selectedSection },
            set: { navModel.selectedSection = $0 }
        )
    }
}
#endif

