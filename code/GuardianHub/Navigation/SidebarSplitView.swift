import SwiftUI

struct SidebarSplitView: View {
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        NavigationSplitView {
            // sidebar list
             List(selection: bindingSelection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .tag(section as AppSection?)
                }
            }
            .navigationTitle("GuardianHub")
        } detail: {
            // detail view on the right
            NavigationStack {
                SectionDetailRouter(selection: navModel.selectedSection)
            }
            .navigationDestination(for: AppSection.self) { section in
                SectionDetailRouter(selection: section)
            }
        }
    }

    private var bindingSelection: Binding<AppSection?> {
        Binding<AppSection?>(
            get: { navModel.selectedSection },
            set: { newValue in
                if let newValue { navModel.selectedSection = newValue }
            }
        )
    }
}

// simple router to show the right view based on selection
private struct SectionDetailRouter: View {
    let selection: AppSection

    var body: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .identityCheck:
            IdentityCheckView()
        case .webAuditor:
            WebAuditorView()
        case .privacyGuard:
            PrivacyGuardView()
        }
    }
}
