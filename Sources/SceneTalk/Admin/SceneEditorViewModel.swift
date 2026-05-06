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

    init(scene: SceneTalkScene, availableObjects: [SceneObject]) {
        self.baseScene = scene
        self.availableObjects = availableObjects
        self.placements = scene.placements
        self.backgroundAssetName = scene.backgroundAssetName
        self.sceneName = scene.name
    }

    // MARK: - Object mutation

    /// Add a newly-authored object to the available set, then immediately place it.
    func addObject(_ object: SceneObject, at point: CGPoint = CGPoint(x: 0.5, y: 0.45)) {
        availableObjects.append(object)
        addPlacement(for: object, at: point)
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

    // MARK: - Build result

    /// Returns the updated `SceneTalkScene` with current placements.
    func buildScene() -> SceneTalkScene {
        SceneTalkScene(
            id: baseScene.id,
            profileId: baseScene.profileId,
            name: sceneName,
            backgroundAssetName: backgroundAssetName,
            placements: placements
        )
    }
}
