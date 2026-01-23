import SwiftUI

struct RootNavigationView: View {
    var body: some View {
        #if os(macOS)
        SidebarSplitView()
        #else
        AdaptiveNavigationHost()
        #endif
    }
}

#if os(iOS)
// switch between tab view (iPhone) and sidebar (iPad)
private struct AdaptiveNavigationHost: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            PhoneTabView()
        } else {
            SidebarSplitView()
        }
    }
}
#endif
