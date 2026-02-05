import SwiftUI

struct SidebarSplitView: View {
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        NavigationSplitView {
            // sidebar list with styled items
            List(selection: bindingSelection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        SidebarRow(section: section, isSelected: navModel.selectedSection == section)
                    }
                    .tag(section as AppSection?)
                }
            }
            .listStyle(.sidebar)
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

// Custom sidebar row with gradient icon
private struct SidebarRow: View {
    let section: AppSection
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Gradient icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(section.gradient.opacity(isSelected ? 1 : 0.8))
                    .frame(width: 28, height: 28)
                
                Image(systemName: section.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(section.title)
                .font(.body.weight(isSelected ? .semibold : .regular))
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
        case .webAuditor:
            WebAuditorView()
        case .privacyGuard:
            PrivacyGuardView()
        case .passwordLab:
            PasswordLabView()
        }
    }
}
