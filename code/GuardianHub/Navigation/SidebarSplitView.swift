import SwiftUI

struct SidebarSplitView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .tag(section as AppSection?)
                }
            }
            .navigationTitle("GuardianHub")
        } detail: {
            NavigationStack {
                SectionDetailRouter(selection: selection ?? .dashboard)
            }
            .navigationDestination(for: AppSection.self) { section in
                SectionDetailRouter(selection: section)
            }
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
