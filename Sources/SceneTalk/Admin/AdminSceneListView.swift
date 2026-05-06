import SwiftUI

/// Admin-mode landing page: a grid of editable scenes.
/// Tapping a scene tile pushes `SceneEditorView`; tapping "+ New scene" creates
/// a blank scene and opens the editor immediately.
struct AdminSceneListView: View {

    let profile: Profile
    @Binding var scenes: [SceneTalkScene]
    let availableObjects: [SceneObject]
    /// Persist the current scene list (called on any add / edit / save).
    let onScenesChanged: ([SceneTalkScene]) -> Void
    /// Persist a cutout PNG for a new object (forwarded to ProfileStore).
    let saveCutout: ((Data, UUID) throws -> String)?
    /// Persist recorded audio for a new object (forwarded to ProfileStore).
    let saveAudio: ((Data, UUID) throws -> String)?
    /// Persist a scene background photo (forwarded to ProfileStore).
    let saveBackground: ((Data, UUID) throws -> String)?
    /// Called when a new object is created inside the scene editor so the
    /// caller can persist it to the object library.
    let onObjectAdded: ((SceneObject) -> Void)?

    /// Drive navigation by scene UUID (Hashable).
    @State private var navigationTarget: UUID?
    /// Newly-created scenes that haven't been flushed to store.scenes yet.
    /// Keyed by scene ID so the navigationDestination lookup never misses them.
    @State private var pendingScenes: [UUID: SceneTalkScene] = [:]

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(scenes) { scene in
                    Button {
                        navigationTarget = scene.id
                    } label: {
                        SceneTile(scene: scene)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(scene.label), edit scene")
                }

                Button {
                    let newScene = SceneTalkScene(
                        profileId: profile.id,
                        name: String(localized: "New Scene"),
                        backgroundAssetName: nil
                    )
                    // Cache locally so navigationDestination can find the scene
                    // before the async binding save flushes to store.scenes.
                    pendingScenes[newScene.id] = newScene
                    scenes.append(newScene)  // async persist via binding setter
                    navigationTarget = newScene.id
                } label: {
                    NewSceneTile()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Add new scene"))
            }
            .padding(20)
        }
        .navigationDestination(item: $navigationTarget) { sceneId in
            // Check store.scenes first; fall back to pendingScenes so newly-
            // created scenes are reachable before the async save completes.
            let scene = scenes.first(where: { $0.id == sceneId })
                     ?? pendingScenes[sceneId]
            if let scene {
                SceneEditorView(
                    scene: scene,
                    availableObjects: availableObjects,
                    profileId: profile.id,
                    saveCutout: saveCutout,
                    saveAudio: saveAudio,
                    saveBackground: saveBackground,
                    onObjectAdded: onObjectAdded
                ) { updated in
                    // Clean up the pending cache for this scene.
                    pendingScenes.removeValue(forKey: updated.id)

                    // Build the authoritative updated array from the current
                    // store snapshot, then assign it once via the binding.
                    // A single assignment = a single async save — no race
                    // condition from a second onScenesChanged call.
                    var current = scenes
                    if let idx = current.firstIndex(where: { $0.id == updated.id }) {
                        current[idx] = updated
                    } else {
                        current.append(updated)
                    }
                    scenes = current        // one authoritative save via binding setter
                    navigationTarget = nil  // explicit pop (don't rely on dismiss())
                }
            } else {
                // Scene was deleted while navigating — pop back gracefully
                Color.clear.onAppear { navigationTarget = nil }
            }
        }
    }
}

// MARK: - Scene tile

private struct SceneTile: View {
    let scene: SceneTalkScene

    var body: some View {
        VStack(spacing: 0) {
            // Background thumbnail (same logic as patient SceneGridView)
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
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }

                // Edit hint overlay (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Color.white, Color.accentColor)
                            .font(.title2)
                            .padding(8)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }
            }

            // Scene name
            Text(scene.label)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - "+ New scene" tile

private struct NewSceneTile: View {

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.accentColor.opacity(0.7),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .background(
                        Color.accentColor.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .aspectRatio(4/3, contentMode: .fit)

                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    Text(String(localized: "New Scene"))
                        .font(.headline)
                        .foregroundStyle(.tint)
                }
            }

            Text(" ") // align baseline with SceneTile name area
                .font(.headline)
                .padding(.vertical, 10)
        }
    }
}

// MARK: - Helpers

private extension SceneTalkScene {
    /// Display label used in the tile (currently just `name`).
    var label: String { name }
}
