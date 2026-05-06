import SwiftUI

/// Shows a single Scene: full-bleed background + tappable object placements.
/// Tapping an object plays its audio and shows the label prominently.
struct SceneView: View {

    let scene: SceneTalkScene
    let objects: [SceneObject]        // full library — looked up by Placement.objectId
    let essentialsConfig: EssentialsConfig
    let audioService: any AudioService
    let language: Language
    let onBack: () -> Void
    let onLockTapped: () -> Void

    @State private var lastTappedLabel: String? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background
                background(in: geo)

                // Placements (sorted by zIndex)
                ForEach(scene.placements.sorted(by: { $0.zIndex < $1.zIndex })) { placement in
                    if let obj = objects.first(where: { $0.id == placement.objectId }) {
                        placementView(placement: placement, object: obj, size: geo.size)
                    }
                }

                // Label flash overlay
                labelFlash

                // Essentials bar — leading/trailing get vertical variant, top/bottom horizontal
                essentialsOverlay

                // Navigation row
                navigationRow
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background

    @ViewBuilder
    private func background(in geo: GeometryProxy) -> some View {
        if let assetName = scene.backgroundAssetName,
           let url = documentsURL(for: assetName),
           let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        } else {
            // No background yet — placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.indigo.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text(scene.name)
                            .font(.title.bold())
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    // MARK: - Placement view

    private func placementView(placement: Placement, object: SceneObject, size: CGSize) -> some View {
        let x = placement.x * size.width
        let y = placement.y * size.height
        let w = placement.width * size.width
        let h = placement.height * size.height

        return ObjectTileView(object: object, width: w, height: h) {
            handleTap(object: object)
        }
        .position(x: x + w / 2, y: y + h / 2)
    }

    // MARK: - Label flash

    @ViewBuilder
    private var labelFlash: some View {
        if let label = lastTappedLabel {
            VStack {
                Spacer()
                Text(label)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom, essentialsConfig.position == .bottom ? 100 : 40)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            .animation(.easeInOut(duration: 0.2), value: label)
        }
    }

    // MARK: - Essentials overlay

    @ViewBuilder
    private var essentialsOverlay: some View {
        switch essentialsConfig.position {
        case .top:
            VStack {
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
                Spacer()
            }
        case .bottom:
            VStack {
                Spacer()
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
            }
        case .leading:
            HStack {
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
                Spacer()
            }
        case .trailing:
            HStack {
                Spacer()
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
            }
        }
    }

    // MARK: - Navigation row

    private var navigationRow: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Back to scene list")
            .padding(16)

            Spacer()

            Button(action: onLockTapped) {
                Image(systemName: "lock.fill")
                    .imageScale(.medium)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Admin access")
            .padding(16)
        }
    }

    // MARK: - Tap handler

    private func handleTap(object: SceneObject) {
        withAnimation {
            lastTappedLabel = object.label
        }
        Task { await audioService.play(object: object, language: language) }
        // Clear label after a short display window
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { lastTappedLabel = nil }
        }
    }

    // MARK: - Helpers

    private func documentsURL(for filename: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(filename)
    }
}

// MARK: - ObjectTileView

/// A tappable tile representing a single SceneObject placed in a Scene.
private struct ObjectTileView: View {

    let object: SceneObject
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Object image (cutout) or placeholder icon
                objectImage
                    .frame(width: width * 0.75, height: height * 0.65)

                // Label
                Text(object.label)
                    .font(.system(size: min(width * 0.14, 16), weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: width)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(object.label)
        .accessibilityHint("Tap to speak: \(object.ttsText)")
    }

    @ViewBuilder
    private var objectImage: some View {
        if let assetName = object.imageAssetName,
           let url = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(assetName),
           let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            // Placeholder icon until cutout is authored
            Image(systemName: object.kind == .phraseIntent ? "bubble.left.fill" : "photo")
                .font(.system(size: width * 0.3))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
