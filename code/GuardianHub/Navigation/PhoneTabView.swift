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
            // dashboard
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(AppSection.dashboard.title, systemImage: AppSection.dashboard.systemImage)
            }
            .tag(AppSection.dashboard)

            // identity check
            NavigationStack {
                IdentityCheckView()
            }
            .tabItem {
                Label(AppSection.identityCheck.title, systemImage: AppSection.identityCheck.systemImage)
            }
            .tag(AppSection.identityCheck)

            // web auditor
            NavigationStack {
                WebAuditorView()
            }
            .tabItem {
                Label(AppSection.webAuditor.title, systemImage: AppSection.webAuditor.systemImage)
            }
            .tag(AppSection.webAuditor)

            // privacy guard
            NavigationStack {
                PrivacyGuardView()
            }
            .tabItem {
                Label(AppSection.privacyGuard.title, systemImage: AppSection.privacyGuard.systemImage)
            }
            .tag(AppSection.privacyGuard)

            // password lab
            NavigationStack {
                PasswordLabView()
            }
            .tabItem {
                Label(AppSection.passwordLab.title, systemImage: AppSection.passwordLab.systemImage)
            }
            .tag(AppSection.passwordLab)
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

