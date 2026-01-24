import SwiftUI

struct RootNavigationView: View {
    @State private var navModel = AppNavigationModel()
    @State private var identitySettings = IdentityCheckRuntimeSettings()

    var body: some View {
        #if os(macOS)
        SidebarSplitView()
            .environment(navModel)
            .environment(identitySettings)
        #else
        AdaptiveNavigationHost()
            .environment(navModel)
            .environment(identitySettings)
        #endif
    }
}

#if os(iOS)
// switch between tab view (iPhone) and sidebar (iPad)
private struct AdaptiveNavigationHost: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppNavigationModel.self) private var navModel

    var body: some View {
        if horizontalSizeClass == .compact {
            PhoneTabView()
        } else {
            SidebarSplitView()
        }
    }
}
#endif
