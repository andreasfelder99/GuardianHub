import SwiftUI

#if os(iOS)
struct PhoneTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(AppSection.dashboard.title, systemImage: AppSection.dashboard.systemImage)
            }

            NavigationStack {
                IdentityCheckView()
            }
            .tabItem {
                Label(AppSection.identityCheck.title, systemImage: AppSection.identityCheck.systemImage)
            }
        }
    }
}
#endif
