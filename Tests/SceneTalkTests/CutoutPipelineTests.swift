import XCTest
@testable import SceneTalk

/// Tests for the CutoutPipeline state machine.
/// The Vision processing and AVFoundation recording are not exercised here
/// (hardware-dependent); we test the state transitions through the public API.
@MainActor
final class CutoutPipelineTests: XCTestCase {

    // MARK: - Initial state

    func test_initialStep_isChoosePhoto() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        XCTAssertEqual(vm.step, .choosePhoto)
    }

    func test_hasNoCutoutInitially() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        XCTAssertFalse(vm.hasCutout)
    }

    func test_hasNoAudioInitially() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        XCTAssertFalse(vm.hasRecording)
    }

    // MARK: - Step transitions

    func test_confirmCutout_advancesToRecordVoice() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        // Simulate Vision result arriving
        vm.didExtractCutout(imageData: Data([0x89, 0x50])) // fake PNG header bytes
        XCTAssertEqual(vm.step, .confirmCutout)
        vm.confirmCutout()
        XCTAssertEqual(vm.step, .recordVoice)
        XCTAssertTrue(vm.hasCutout)
    }

    func test_retakeCutout_returnsToChoosePhoto() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.didExtractCutout(imageData: Data([0x89]))
        vm.retakeCutout()
        XCTAssertEqual(vm.step, .choosePhoto)
        XCTAssertFalse(vm.hasCutout)
    }

    func test_skipRecording_advancesToLabelEntry() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.didExtractCutout(imageData: Data([0x89]))
        vm.confirmCutout()
        vm.skipRecording()
        XCTAssertEqual(vm.step, .enterLabel)
    }

    func test_didRecord_advancesToLabelEntry() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.didExtractCutout(imageData: Data([0x89]))
        vm.confirmCutout()
        vm.didRecord(audioData: Data([0x00, 0x01]))
        XCTAssertEqual(vm.step, .enterLabel)
        XCTAssertTrue(vm.hasRecording)
    }

    // MARK: - Label entry and save

    func test_labelTrimmed_onSave() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.label = "  Apple  "
        let saved = vm.buildObject()
        XCTAssertEqual(saved?.label, "Apple")
    }

    func test_buildObject_returnsNil_whenLabelEmpty() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.label = ""
        XCTAssertNil(vm.buildObject())
    }

    func test_buildObject_withKindNoun() {
        let vm = CutoutPipelineViewModel(profileId: UUID(), existingObject: nil)
        vm.label = "Apple"
        vm.kind = .noun
        let obj = vm.buildObject()
        XCTAssertEqual(obj?.kind, .noun)
    }

    func test_buildObject_withKindPhraseIntent() {
        let pid = UUID()
        let vm = CutoutPipelineViewModel(profileId: pid, existingObject: nil)
        vm.label = "Call nurse"
        vm.kind = .phraseIntent
        let obj = vm.buildObject()
        XCTAssertEqual(obj?.kind, .phraseIntent)
        XCTAssertEqual(obj?.profileId, pid)
    }
}
