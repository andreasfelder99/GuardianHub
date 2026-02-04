import SwiftUI

/**
 * PhoneTabView is the view for the phone tab.
 * It is used to display major tools in a compact tab bar.
 */

#if os(iOS)
struct PhoneTabView: View {
    @Environment(AppNavigationModel.self) private var navModel

    // A dedicated tab enum keeps TabView selection stable.
    private enum PhoneTab: Hashable {
        case dashboard
        case identityCheck
        case webAuditor
        case more
    }

    @State private var selectedTab: PhoneTab = .dashboard

    private let primarySections: [AppSection] = [
        .dashboard,
        .identityCheck,
        .webAuditor
    ]

    private let moreSections: [AppSection] = [
        .privacyGuard,
        .passwordLab
    ]

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                DashboardView()
                    .onAppear { navModel.selectedSection = .dashboard }
            }
            .tabItem {
                Label(AppSection.dashboard.title, systemImage: AppSection.dashboard.systemImage)
            }
            .tag(PhoneTab.dashboard)

            NavigationStack {
                IdentityCheckView()
                    .onAppear { navModel.selectedSection = .identityCheck }
            }
            .tabItem {
                Label(AppSection.identityCheck.title, systemImage: AppSection.identityCheck.systemImage)
            }
            .tag(PhoneTab.identityCheck)

            NavigationStack {
                WebAuditorView()
                    .onAppear { navModel.selectedSection = .webAuditor }
            }
            .tabItem {
                Label(AppSection.webAuditor.title, systemImage: AppSection.webAuditor.systemImage)
            }
            .tag(PhoneTab.webAuditor)

            NavigationStack {
                moreRoot
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(PhoneTab.more)
        }
        .onAppear {
            // Ensure initial sync when opening on iPhone.
            selectedTab = tab(for: navModel.selectedSection)
        }
        .onChange(of: navModel.selectedSection) { _, newValue in
            // Keep tab selection aligned when dashboard tiles or other logic updates selectedSection.
            selectedTab = tab(for: newValue)
        }
    }

    // MARK: - More

    private var moreRoot: some View {
        List {
            Section("Tools") {
                ForEach(moreSections) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.systemImage)
                    }
                }
            }

            Section {
                Text("Password Lab runs fully offline. Nothing is stored or sent.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("More")
        .navigationDestination(for: AppSection.self) { section in
            // When navigating from More, also update global selection for consistency.
            sectionDestination(for: section)
                .onAppear { navModel.selectedSection = section }
        }
    }

    // MARK: - Routing

    @ViewBuilder
    private func sectionDestination(for section: AppSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView()
        case .identityCheck:
            IdentityCheckView()
        case .webAuditor:
            WebAuditorView()
        case .privacyGuard:
            PrivacyGuardView()
        case .passwordLab:
            PasswordLabView()
        }
    }

    private func tab(for section: AppSection) -> PhoneTab {
        switch section {
        case .dashboard: return .dashboard
        case .identityCheck: return .identityCheck
        case .webAuditor: return .webAuditor
        case .privacyGuard, .passwordLab:
            return .more
        }
    }
}
#endif
