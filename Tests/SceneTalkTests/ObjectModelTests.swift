import XCTest
@testable import SceneTalk

/// Tests for the Object, ObjectKind, Scene, and Placement models.
final class ObjectModelTests: XCTestCase {

    // MARK: - Object

    func test_object_defaults() {
        let obj = SceneObject(
            profileId: UUID(),
            label: "Apple",
            kind: .noun
        )
        XCTAssertFalse(obj.id.uuidString.isEmpty)
        XCTAssertEqual(obj.label, "Apple")
        XCTAssertEqual(obj.kind, .noun)
        XCTAssertNil(obj.audioAssetName, "New object has no audio yet")
        XCTAssertNil(obj.imageAssetName, "New object has no image yet")
        XCTAssertNil(obj.ttsOverride, "ttsOverride defaults to nil (uses label)")
    }

    func test_object_phraseIntent_kind() {
        let obj = SceneObject(profileId: UUID(), label: "Call nurse", kind: .phraseIntent)
        XCTAssertEqual(obj.kind, .phraseIntent)
    }

    func test_object_ttsText_prefersTTSOverride() {
        let obj = SceneObject(
            profileId: UUID(),
            label: "Call nurse",
            kind: .phraseIntent,
            ttsOverride: "Please call the nurse"
        )
        XCTAssertEqual(obj.ttsText, "Please call the nurse")
    }

    func test_object_ttsText_fallsBackToLabel() {
        let obj = SceneObject(profileId: UUID(), label: "Apple", kind: .noun)
        XCTAssertEqual(obj.ttsText, "Apple")
    }

    func test_object_equality_byID() {
        let id = UUID()
        let pid = UUID()
        let a = SceneObject(id: id, profileId: pid, label: "A", kind: .noun)
        let b = SceneObject(id: id, profileId: pid, label: "A", kind: .noun)
        XCTAssertEqual(a, b)
    }

    func test_twoObjectsWithDifferentIDs_areNotEqual() {
        let pid = UUID()
        let a = SceneObject(profileId: pid, label: "Apple", kind: .noun)
        let b = SceneObject(profileId: pid, label: "Apple", kind: .noun)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Placement

    func test_placement_storesObjectIDAndGeometry() {
        let objId = UUID()
        let sceneId = UUID()
        let p = Placement(objectId: objId, sceneId: sceneId, x: 0.25, y: 0.5, width: 0.15, height: 0.15)
        XCTAssertEqual(p.objectId, objId)
        XCTAssertEqual(p.sceneId, sceneId)
        XCTAssertEqual(p.x, 0.25, accuracy: 0.001)
        XCTAssertEqual(p.y, 0.5, accuracy: 0.001)
        XCTAssertEqual(p.width, 0.15, accuracy: 0.001)
        XCTAssertEqual(p.height, 0.15, accuracy: 0.001)
    }

    func test_placement_coordinatesAreNormalized_acceptingZeroToOne() {
        // Normalised 0…1 relative to scene background dimensions.
        let p = Placement(objectId: UUID(), sceneId: UUID(), x: 0.0, y: 1.0, width: 0.1, height: 0.1)
        XCTAssertGreaterThanOrEqual(p.x, 0)
        XCTAssertLessThanOrEqual(p.y, 1)
    }

    // MARK: - Scene

    func test_scene_startsWith_noPlacements() {
        let scene = SceneTalkScene(profileId: UUID(), name: "Kitchen")
        XCTAssertTrue(scene.placements.isEmpty)
    }

    func test_scene_canAddPlacement() {
        var scene = SceneTalkScene(profileId: UUID(), name: "Kitchen")
        let placement = Placement(objectId: UUID(), sceneId: scene.id, x: 0.3, y: 0.4, width: 0.1, height: 0.1)
        scene.placements.append(placement)
        XCTAssertEqual(scene.placements.count, 1)
    }

    func test_scene_equality_byID() {
        let id = UUID()
        let pid = UUID()
        let a = SceneTalkScene(id: id, profileId: pid, name: "Kitchen")
        let b = SceneTalkScene(id: id, profileId: pid, name: "Kitchen")
        XCTAssertEqual(a, b)
    }
}
