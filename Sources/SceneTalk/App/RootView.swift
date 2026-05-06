import SwiftUI

/// Entry point that routes between the first-launch wizard and the main app experience.
/// In slice 1 this is a placeholder; full routing lands in slice 2 (profile/PIN).
struct RootView: View {

    var body: some View {
        Text("SceneTalk")
            .font(.largeTitle)
            .foregroundStyle(.primary)
    }
}

#Preview {
    RootView()
}
