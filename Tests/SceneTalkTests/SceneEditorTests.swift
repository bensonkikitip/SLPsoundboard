import XCTest
@testable import SceneTalk

/// Tests for SceneEditorViewModel — placement CRUD within a scene.
@MainActor
final class SceneEditorTests: XCTestCase {

    private var scene: SceneTalkScene!
    private var objects: [SceneObject]!
    private var vm: SceneEditorViewModel!
    private let profileId = UUID()

    override func setUp() {
        super.setUp()
        scene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        objects = [
            SceneObject(profileId: profileId, label: "Apple", kind: .noun),
            SceneObject(profileId: profileId, label: "Cup", kind: .noun),
        ]
        vm = SceneEditorViewModel(scene: scene, availableObjects: objects)
    }

    // MARK: - Initial state

    func test_initialPlacements_matchScene() {
        XCTAssertTrue(vm.placements.isEmpty)
    }

    // MARK: - Add placement

    func test_addPlacement_appearsInList() {
        let obj = objects[0]
        vm.addPlacement(for: obj, at: CGPoint(x: 0.3, y: 0.4))
        XCTAssertEqual(vm.placements.count, 1)
        XCTAssertEqual(vm.placements.first?.objectId, obj.id)
    }

    func test_addPlacement_usesNormalisedCoordinates() {
        vm.addPlacement(for: objects[0], at: CGPoint(x: 0.5, y: 0.5))
        let p = vm.placements[0]
        XCTAssertGreaterThanOrEqual(p.x, 0)
        XCTAssertLessThanOrEqual(p.x, 1)
        XCTAssertGreaterThanOrEqual(p.y, 0)
        XCTAssertLessThanOrEqual(p.y, 1)
    }

    func test_addMultiplePlacements_allAppear() {
        vm.addPlacement(for: objects[0], at: CGPoint(x: 0.2, y: 0.3))
        vm.addPlacement(for: objects[1], at: CGPoint(x: 0.6, y: 0.7))
        XCTAssertEqual(vm.placements.count, 2)
    }

    // MARK: - Move placement

    func test_movePlacement_updatesPosition() {
        vm.addPlacement(for: objects[0], at: CGPoint(x: 0.2, y: 0.2))
        let id = vm.placements[0].id
        vm.movePlacement(id: id, to: CGPoint(x: 0.6, y: 0.8))
        XCTAssertEqual(vm.placements[0].x, 0.6, accuracy: 0.001)
        XCTAssertEqual(vm.placements[0].y, 0.8, accuracy: 0.001)
    }

    // MARK: - Delete placement

    func test_deletePlacement_removesFromList() {
        vm.addPlacement(for: objects[0], at: CGPoint(x: 0.3, y: 0.3))
        let id = vm.placements[0].id
        vm.deletePlacement(id: id)
        XCTAssertTrue(vm.placements.isEmpty)
    }

    // MARK: - Build updated scene

    func test_buildScene_containsAllPlacements() {
        vm.addPlacement(for: objects[0], at: CGPoint(x: 0.1, y: 0.1))
        vm.addPlacement(for: objects[1], at: CGPoint(x: 0.5, y: 0.5))
        let updated = vm.buildScene()
        XCTAssertEqual(updated.placements.count, 2)
    }

    func test_buildScene_preservesSceneID() {
        let updated = vm.buildScene()
        XCTAssertEqual(updated.id, scene.id)
    }

    func test_buildScene_preservesSceneName() {
        let updated = vm.buildScene()
        XCTAssertEqual(updated.name, scene.name)
    }
}
