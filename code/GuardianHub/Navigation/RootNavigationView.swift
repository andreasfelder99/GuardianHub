import SwiftUI

struct RootNavigationView: View {
    @State private var navModel = AppNavigationModel()

    var body: some View {
        #if os(macOS)
        SidebarSplitView()
            .environment(navModel)
        #else
        AdaptiveNavigationHost()
            .environment(navModel)
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
