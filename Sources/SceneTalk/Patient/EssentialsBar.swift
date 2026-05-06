import SwiftUI

/// The always-visible strip of one-tap communication shortcuts.
/// Position (top/bottom/leading/trailing) and content are per-profile.
/// Present on every screen in Patient mode.
struct EssentialsBar: View {

    let config: EssentialsConfig
    let audioService: any AudioService
    let language: Language

    // Hit-target size comes from the profile's layout preference (passed in via environment in slice 16)
    var itemSize: CGFloat = 80

    var body: some View {
        Group {
            switch config.position {
            case .top, .bottom:
                horizontalBar
            case .leading, .trailing:
                verticalBar
            }
        }
    }

    // MARK: - Layouts

    private var horizontalBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(config.items) { item in
                    EssentialButton(
                        item: item,
                        size: itemSize,
                        audioService: audioService,
                        language: language
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
    }

    private var verticalBar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(config.items) { item in
                    EssentialButton(
                        item: item,
                        size: itemSize,
                        audioService: audioService,
                        language: language
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Individual button

private struct EssentialButton: View {

    let item: EssentialItem
    let size: CGFloat
    let audioService: any AudioService
    let language: Language

    @State private var isPressed = false

    var body: some View {
        Button {
            speak()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.systemImageName)
                    .imageScale(.large)
                    .font(.system(size: size * 0.35))
                    .frame(width: size * 0.6, height: size * 0.5)
                Text(item.label)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: size - 8)
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.08), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(item.label)
        .accessibilityHint("Tap to speak: \(item.ttsText)")
    }

    private func speak() {
        // Build a temporary SceneObject to reuse AudioService's playback logic.
        let obj = SceneObject(
            profileId: UUID(), // essentials are not profile-scoped objects
            label: item.label,
            kind: .phraseIntent,
            audioAssetName: item.audioAssetName,
            ttsOverride: item.ttsText
        )
        Task { await audioService.play(object: obj, language: language) }
    }
}

#Preview {
    VStack {
        Spacer()
        EssentialsBar(
            config: .default(language: .english),
            audioService: MockAudioService(),
            language: .english
        )
    }
}
