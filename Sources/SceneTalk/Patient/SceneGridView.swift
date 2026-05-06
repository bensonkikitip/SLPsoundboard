import SwiftUI

/// The patient's home screen: a grid of Scene tiles.
/// Tapping a tile navigates into that Scene.
struct SceneGridView: View {

    let scenes: [SceneTalkScene]
    let objects: [SceneObject]         // full Object Library for this profile
    let essentialsConfig: EssentialsConfig
    let audioService: any AudioService
    let language: Language
    let onLockTapped: () -> Void

    @State private var selectedScene: SceneTalkScene?

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 20)
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main content
            if scenes.isEmpty {
                emptyState
            } else {
                gridContent
            }

            // Lock icon — tapping opens PIN entry
            lockButton
        }
        .fullScreenCover(item: $selectedScene) { scene in
            SceneView(
                scene: scene,
                objects: objects,
                essentialsConfig: essentialsConfig,
                audioService: audioService,
                language: language,
                onBack: { selectedScene = nil },
                onLockTapped: onLockTapped
            )
        }
    }

    // MARK: - Grid

    private var gridContent: some View {
        VStack(spacing: 0) {
            if essentialsConfig.position == .top {
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(scenes) { scene in
                        SceneTileView(scene: scene)
                            .onTapGesture { selectedScene = scene }
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)

            if essentialsConfig.position == .bottom {
                EssentialsBar(config: essentialsConfig, audioService: audioService, language: language)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text(String(localized: "No Scenes Yet"))
                .font(.title2.weight(.semibold))
            Text(String(localized: "Ask your family or SLP to add scenes in Admin mode."))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Lock button

    private var lockButton: some View {
        Button(action: onLockTapped) {
            Image(systemName: "lock.fill")
                .imageScale(.large)
                .padding(14)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(String(localized: "Admin access"))
        .padding(16)
    }
}

// MARK: - Scene tile

private struct SceneTileView: View {

    let scene: SceneTalkScene

    var body: some View {
        VStack(spacing: 0) {
            // Background thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.12))
                    .aspectRatio(4/3, contentMode: .fit)

                if let style = ProceduralBackground.style(from: scene.backgroundAssetName) {
                    ProceduralSceneBackgroundView(style: style)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if let assetName = scene.backgroundAssetName,
                          let url = FileManager.default
                            .urls(for: .documentDirectory, in: .userDomainMask)
                            .first?.appendingPathComponent(assetName),
                          let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }

            // Scene name
            Text(scene.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel(scene.name)
        .accessibilityAddTraits(.isButton)
    }
}
