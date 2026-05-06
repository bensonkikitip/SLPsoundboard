import XCTest
@testable import SceneTalk

/// Tests for SceneHotspot encode/decode and SceneTalkScene backward-compatibility.
final class SceneHotspotTests: XCTestCase {

    private let profileId = UUID()
    private let sceneId = UUID()

    // MARK: - SceneHotspot encode/decode

    func test_sceneHotspot_encodeDecodeRoundTrip() throws {
        let original = SceneHotspot(
            sceneId: sceneId,
            label: "Stove",
            x: 0.1,
            y: 0.2,
            width: 0.3,
            height: 0.25,
            audioAssetName: "abc/audio/123.m4a",
            ttsOverride: "The stove"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SceneHotspot.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.sceneId, original.sceneId)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.x, original.x)
        XCTAssertEqual(decoded.y, original.y)
        XCTAssertEqual(decoded.width, original.width)
        XCTAssertEqual(decoded.height, original.height)
        XCTAssertEqual(decoded.audioAssetName, original.audioAssetName)
        XCTAssertEqual(decoded.ttsOverride, original.ttsOverride)
    }

    func test_sceneHotspot_ttsText_usesOverride_whenPresent() {
        let hotspot = SceneHotspot(sceneId: sceneId, label: "Stove", x: 0, y: 0, width: 0.1, height: 0.1, ttsOverride: "The kitchen stove")
        XCTAssertEqual(hotspot.ttsText, "The kitchen stove")
    }

    func test_sceneHotspot_ttsText_fallsBackToLabel_whenNoOverride() {
        let hotspot = SceneHotspot(sceneId: sceneId, label: "Sink", x: 0, y: 0, width: 0.1, height: 0.1)
        XCTAssertEqual(hotspot.ttsText, "Sink")
    }

    // MARK: - SceneTalkScene backward compatibility

    /// A scene JSON from before hotspots existed must decode without throwing.
    func test_sceneTalkScene_decodesLegacy_withoutHotspots() throws {
        let legacyJSON = """
        {
            "id": "\(sceneId.uuidString)",
            "profileId": "\(profileId.uuidString)",
            "name": "Kitchen",
            "placements": []
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let scene = try JSONDecoder().decode(SceneTalkScene.self, from: data)
        XCTAssertEqual(scene.hotspots, [], "Legacy scenes must have empty hotspots array")
        XCTAssertEqual(scene.name, "Kitchen")
    }

    func test_sceneTalkScene_decodesWithHotspots() throws {
        let hotspot = SceneHotspot(sceneId: sceneId, label: "Fridge", x: 0.5, y: 0.2, width: 0.2, height: 0.3)
        var scene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        scene.hotspots = [hotspot]

        let data = try JSONEncoder().encode(scene)
        let decoded = try JSONDecoder().decode(SceneTalkScene.self, from: data)

        XCTAssertEqual(decoded.hotspots.count, 1)
        XCTAssertEqual(decoded.hotspots[0].label, "Fridge")
        XCTAssertEqual(decoded.hotspots[0].x, 0.5)
    }

    func test_sceneTalkScene_encodeDecodeRoundTrip_withMultipleHotspots() throws {
        let h1 = SceneHotspot(sceneId: sceneId, label: "Stove", x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        let h2 = SceneHotspot(sceneId: sceneId, label: "Sink", x: 0.6, y: 0.3, width: 0.15, height: 0.25, audioAssetName: "abc/audio/xyz.m4a")
        var scene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        scene.hotspots = [h1, h2]

        let data = try JSONEncoder().encode(scene)
        let decoded = try JSONDecoder().decode(SceneTalkScene.self, from: data)

        XCTAssertEqual(decoded.hotspots.count, 2)
        XCTAssertEqual(decoded.hotspots[1].audioAssetName, "abc/audio/xyz.m4a")
    }
}
