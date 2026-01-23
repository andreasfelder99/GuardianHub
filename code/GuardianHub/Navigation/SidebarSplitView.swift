import SwiftUI

struct SidebarSplitView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section as AppSection?)
            }
            .navigationTitle("GuardianHub")
        } detail: {
            SectionDetailRouter(selection: selection ?? .dashboard)
        }
    }
}

private struct SectionDetailRouter: View {
    let selection: AppSection

    var body: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .identityCheck:
            IdentityCheckView()
        }
    }
}
