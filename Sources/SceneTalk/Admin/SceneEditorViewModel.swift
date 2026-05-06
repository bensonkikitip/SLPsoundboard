import Foundation
import Observation

/// State machine for the Scene editor: manages Placements within one Scene.
/// The `buildScene()` method produces the updated `SceneTalkScene` for persistence.
@Observable
@MainActor
final class SceneEditorViewModel {

    private let baseScene: SceneTalkScene
    var sceneId: UUID { baseScene.id }
    private(set) var availableObjects: [SceneObject]

    private(set) var placements: [Placement]
    var backgroundAssetName: String?
    var sceneName: String

    private(set) var hotspots: [SceneHotspot]

    init(scene: SceneTalkScene, availableObjects: [SceneObject]) {
        self.baseScene = scene
        self.availableObjects = availableObjects
        self.placements = scene.placements
        self.hotspots = scene.hotspots
        self.backgroundAssetName = scene.backgroundAssetName
        self.sceneName = scene.name
    }

    // MARK: - Object mutation

    /// Add a newly-authored object to the available set, then immediately place it.
    func addObject(_ object: SceneObject, at point: CGPoint = CGPoint(x: 0.5, y: 0.45)) {
        registerObject(object)
        addPlacement(for: object, at: point)
    }

    /// Register an object in the available set without placing it.
    /// Call this before `addPlacement` when placement is handled separately.
    func registerObject(_ object: SceneObject) {
        guard !availableObjects.contains(where: { $0.id == object.id }) else { return }
        availableObjects.append(object)
    }

    // MARK: - Placement CRUD

    /// Add a new placement for `object` at the given normalised position.
    func addPlacement(for object: SceneObject, at point: CGPoint) {
        let p = Placement(
            objectId: object.id,
            sceneId: baseScene.id,
            x: point.x,
            y: point.y
        )
        placements.append(p)
    }

    /// Move an existing placement to a new normalised position.
    func movePlacement(id: UUID, to point: CGPoint) {
        guard let idx = placements.firstIndex(where: { $0.id == id }) else { return }
        placements[idx].x = point.x
        placements[idx].y = point.y
    }

    /// Resize a placement.
    func resizePlacement(id: UUID, width: Double, height: Double) {
        guard let idx = placements.firstIndex(where: { $0.id == id }) else { return }
        placements[idx].width = max(0.04, width)
        placements[idx].height = max(0.04, height)
    }

    /// Delete a placement.
    func deletePlacement(id: UUID) {
        placements.removeAll { $0.id == id }
    }

    // MARK: - Hotspot CRUD

    func addHotspot(_ hotspot: SceneHotspot) {
        hotspots.append(hotspot)
    }

    /// Replace an existing hotspot (matched by id). No-op if the id is unknown.
    func updateHotspot(_ hotspot: SceneHotspot) {
        guard let idx = hotspots.firstIndex(where: { $0.id == hotspot.id }) else { return }
        hotspots[idx] = hotspot
    }

    func deleteHotspot(id: UUID) {
        hotspots.removeAll { $0.id == id }
    }

    // MARK: - Build result

    /// Returns the updated `SceneTalkScene` with current placements and hotspots.
    func buildScene() -> SceneTalkScene {
        SceneTalkScene(
            id: baseScene.id,
            profileId: baseScene.profileId,
            name: sceneName,
            backgroundAssetName: backgroundAssetName,
            placements: placements,
            hotspots: hotspots
        )
    }
}
