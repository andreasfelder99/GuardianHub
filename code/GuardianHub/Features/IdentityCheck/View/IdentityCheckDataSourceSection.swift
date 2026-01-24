import SwiftUI

struct IdentityCheckDataSourceSection: View {
    @Environment(IdentityCheckRuntimeSettings.self) private var settings

    let resolutionText: String

    var body: some View {
        Section("Data Source") {
            Picker(
                "Mode",
                selection: Binding<BreachCheckServiceMode>(
                    get: { settings.preferredMode },
                    set: { settings.preferredMode = $0 }
                )
            ) {
                ForEach(BreachCheckServiceMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode as BreachCheckServiceMode)
                }
            }

            Text(resolutionText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
