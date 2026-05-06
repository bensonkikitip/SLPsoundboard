import XCTest
@testable import SceneTalk

/// Tests for AudioService behavior through a mock implementation.
/// Real AVFoundation calls are exercised via LiveAudioService in integration/UI testing.
@MainActor
final class AudioServiceTests: XCTestCase {

    private var service: MockAudioService!
    private var profileId: UUID!

    override func setUp() {
        super.setUp()
        service = MockAudioService()
        profileId = UUID()
    }

    // MARK: - Play with audio asset

    func test_play_withAudioAsset_speaksAssetNotTTS() async {
        let obj = SceneObject(
            profileId: profileId,
            label: "Apple",
            kind: .noun,
            audioAssetName: "apple_mom.m4a"
        )
        await service.play(object: obj, language: .english)
        XCTAssertEqual(service.lastPlayedAsset, "apple_mom.m4a")
        XCTAssertNil(service.lastSpokenText, "Should not use TTS when audio asset exists")
    }

    // MARK: - TTS fallback

    func test_play_withNoAudioAsset_usesTTSWithLabel() async {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        await service.play(object: obj, language: .english)
        XCTAssertNil(service.lastPlayedAsset)
        XCTAssertEqual(service.lastSpokenText, "Apple")
    }

    func test_play_withTTSOverride_speaksOverrideText() async {
        let obj = SceneObject(
            profileId: profileId,
            label: "Nurse",
            kind: .phraseIntent,
            ttsOverride: "Please call the nurse"
        )
        await service.play(object: obj, language: .english)
        XCTAssertEqual(service.lastSpokenText, "Please call the nurse")
    }

    func test_play_usesProfileLanguageForTTS() async {
        let obj = SceneObject(profileId: profileId, label: "Manzana", kind: .noun)
        await service.play(object: obj, language: .spanish)
        XCTAssertEqual(service.lastSpokenLanguage, .spanish)
    }

    // MARK: - Stop

    func test_stop_isCalledBeforeNewPlayback() async {
        let obj1 = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        let obj2 = SceneObject(profileId: profileId, label: "Water", kind: .noun)
        await service.play(object: obj1, language: .english)
        await service.play(object: obj2, language: .english)
        XCTAssertGreaterThanOrEqual(service.stopCallCount, 1,
            "stop() should be called before each new play to avoid overlapping audio")
    }

    func test_stop_haltsPlayback() async {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        await service.play(object: obj, language: .english)
        let countBeforeExplicitStop = service.stopCallCount
        service.stop()
        XCTAssertEqual(service.stopCallCount, countBeforeExplicitStop + 1,
            "An explicit stop() call should increment the stop count by 1")
    }
}
