import SwiftUI

struct RateLimitNoticeView: View {
    let until: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let remaining = max(0, Int(until.timeIntervalSinceNow.rounded(.up)))

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "hourglass")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate limit reached")
                        .font(.headline)

                    Text("Please wait \(remaining) second\(remaining == 1 ? "" : "s") before trying again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }
}
