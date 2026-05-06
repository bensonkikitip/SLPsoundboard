import Foundation
import Observation

/// Per-profile observable store of SceneObjects.
///
/// This is the in-memory representation; persistence is added in slice 12
/// (EncryptedLocalRepository for hospital) and slice 13 (CloudKitRepository for home).
/// Views observe `objects` directly — mutations via `add/update/delete`.
@Observable
@MainActor
final class ObjectLibrary {

    let profileId: UUID
    private(set) var objects: [SceneObject] = []

    init(profileId: UUID, objects: [SceneObject] = []) {
        self.profileId = profileId
        self.objects = objects
    }

    // MARK: - CRUD

    func add(_ object: SceneObject) {
        objects.append(object)
    }

    func update(_ object: SceneObject) {
        guard let idx = objects.firstIndex(where: { $0.id == object.id }) else { return }
        objects[idx] = object
    }

    func delete(_ object: SceneObject) {
        objects.removeAll { $0.id == object.id }
    }

    // MARK: - Lookup

    func object(id: UUID) -> SceneObject? {
        objects.first { $0.id == id }
    }

    func objects(kind: ObjectKind) -> [SceneObject] {
        objects.filter { $0.kind == kind }
    }
}
