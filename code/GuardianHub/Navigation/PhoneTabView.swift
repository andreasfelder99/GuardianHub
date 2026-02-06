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
        case privacyGuard
        case more
    }

    @State private var selectedTab: PhoneTab = .dashboard

    private let primarySections: [AppSection] = [
        .dashboard,
        .identityCheck,
        .privacyGuard
    ]

    private let moreSections: [AppSection] = [
        .webAuditor,
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
                PrivacyGuardView()
                    .onAppear { navModel.selectedSection = .privacyGuard }
            }
            .tabItem {
                Label(AppSection.privacyGuard.title, systemImage: AppSection.privacyGuard.systemImage)
            }
            .tag(PhoneTab.privacyGuard)

            NavigationStack {
                moreRoot
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(PhoneTab.more)
        }
        .tint(GuardianTheme.SectionColor.dashboard.primaryColor)
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
            Section {
                ForEach(moreSections) { section in
                    NavigationLink(value: section) {
                        MoreSectionRow(section: section)
                    }
                }
            } header: {
                Text("Tools")
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.title3)
                        .foregroundStyle(GuardianTheme.StatusGradient.success.gradient)
                    
                    Text("All analysis happens on your device. Nothing is stored or sent anywhere.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
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
        case .privacyGuard: return .privacyGuard
        case .webAuditor, .passwordLab:
            return .more
        }
    }
}

// Custom row for More section with gradient icons
private struct MoreSectionRow: View {
    let section: AppSection
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(section.gradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: section.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.body.weight(.medium))
                
                Text(descriptionFor(section))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func descriptionFor(_ section: AppSection) -> String {
        switch section {
        case .webAuditor: return "Check HTTPS and security headers"
        case .passwordLab: return "Test password strength and crack time"
        default: return ""
        }
    }
}
#endif
