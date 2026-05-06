import XCTest
@testable import SceneTalk

/// Tests for hotspot CRUD in SceneEditorViewModel.
@MainActor
final class SceneEditorViewModelHotspotTests: XCTestCase {

    private var scene: SceneTalkScene!
    private var vm: SceneEditorViewModel!
    private let profileId = UUID()

    override func setUp() {
        super.setUp()
        scene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        vm = SceneEditorViewModel(scene: scene, availableObjects: [])
    }

    // MARK: - Initial state

    func test_initialHotspots_isEmpty() {
        XCTAssertTrue(vm.hotspots.isEmpty)
    }

    func test_initialHotspots_matchScene() {
        let hotspot = SceneHotspot(sceneId: scene.id, label: "Stove", x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        var seededScene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        seededScene.hotspots = [hotspot]
        let seededVM = SceneEditorViewModel(scene: seededScene, availableObjects: [])
        XCTAssertEqual(seededVM.hotspots.count, 1)
        XCTAssertEqual(seededVM.hotspots[0].label, "Stove")
    }

    // MARK: - Add hotspot

    func test_addHotspot_appendsToList() {
        let hotspot = makeHotspot(label: "Stove")
        vm.addHotspot(hotspot)
        XCTAssertEqual(vm.hotspots.count, 1)
        XCTAssertEqual(vm.hotspots[0].label, "Stove")
    }

    func test_addMultipleHotspots_allAppear() {
        vm.addHotspot(makeHotspot(label: "Stove"))
        vm.addHotspot(makeHotspot(label: "Sink"))
        XCTAssertEqual(vm.hotspots.count, 2)
    }

    // MARK: - Update hotspot

    func test_updateHotspot_replacesExisting() {
        let original = makeHotspot(label: "Stov")  // typo
        vm.addHotspot(original)

        var corrected = original
        corrected.label = "Stove"
        vm.updateHotspot(corrected)

        XCTAssertEqual(vm.hotspots.count, 1, "Update must not duplicate")
        XCTAssertEqual(vm.hotspots[0].label, "Stove")
    }

    func test_updateHotspot_ignoresUnknownId() {
        vm.addHotspot(makeHotspot(label: "Stove"))
        let stranger = makeHotspot(label: "Ghost")
        vm.updateHotspot(stranger)  // different id — should be a no-op
        XCTAssertEqual(vm.hotspots.count, 1)
        XCTAssertEqual(vm.hotspots[0].label, "Stove")
    }

    // MARK: - Delete hotspot

    func test_deleteHotspot_removesFromList() {
        let h = makeHotspot(label: "Stove")
        vm.addHotspot(h)
        vm.deleteHotspot(id: h.id)
        XCTAssertTrue(vm.hotspots.isEmpty)
    }

    func test_deleteHotspot_leavesOthersIntact() {
        let h1 = makeHotspot(label: "Stove")
        let h2 = makeHotspot(label: "Sink")
        vm.addHotspot(h1)
        vm.addHotspot(h2)
        vm.deleteHotspot(id: h1.id)
        XCTAssertEqual(vm.hotspots.count, 1)
        XCTAssertEqual(vm.hotspots[0].label, "Sink")
    }

    func test_deleteHotspot_unknownId_isNoOp() {
        vm.addHotspot(makeHotspot(label: "Stove"))
        vm.deleteHotspot(id: UUID())  // random id
        XCTAssertEqual(vm.hotspots.count, 1)
    }

    // MARK: - buildScene

    func test_buildScene_includesHotspots() {
        vm.addHotspot(makeHotspot(label: "Stove"))
        vm.addHotspot(makeHotspot(label: "Sink"))
        let built = vm.buildScene()
        XCTAssertEqual(built.hotspots.count, 2)
    }

    func test_buildScene_hotspots_andPlacements_coexist() {
        let object = SceneObject(profileId: profileId, label: "Cup", kind: .noun)
        vm.registerObject(object)
        vm.addPlacement(for: object, at: CGPoint(x: 0.5, y: 0.5))
        vm.addHotspot(makeHotspot(label: "Stove"))

        let built = vm.buildScene()
        XCTAssertEqual(built.placements.count, 1)
        XCTAssertEqual(built.hotspots.count, 1)
    }

    func test_buildScene_preservesHotspotGeometry() {
        let h = SceneHotspot(sceneId: scene.id, label: "Fridge", x: 0.3, y: 0.4, width: 0.2, height: 0.25)
        vm.addHotspot(h)
        let built = vm.buildScene()
        let rebuilt = built.hotspots[0]
        XCTAssertEqual(rebuilt.x, 0.3)
        XCTAssertEqual(rebuilt.y, 0.4)
        XCTAssertEqual(rebuilt.width, 0.2)
        XCTAssertEqual(rebuilt.height, 0.25)
    }

    // MARK: - Helpers

    private func makeHotspot(label: String) -> SceneHotspot {
        SceneHotspot(sceneId: scene.id, label: label, x: 0.1, y: 0.1, width: 0.2, height: 0.2)
    }
}
