import SwiftUI

struct SidebarSplitView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            // sidebar list
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
            // detail view on the right
            NavigationStack {
                SectionDetailRouter(selection: selection ?? .dashboard)
            }
            .navigationDestination(for: AppSection.self) { section in
                SectionDetailRouter(selection: section)
            }
        }
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
        }
    }
}
