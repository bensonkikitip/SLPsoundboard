import Foundation
import Observation

// MARK: - Pipeline step

enum CutoutPipelineStep: Equatable, Sendable {
    /// User picks or takes a photo.
    case choosePhoto
    /// Vision has extracted a cutout; user confirms or retakes.
    case confirmCutout
    /// User records (or skips) a short voice clip.
    case recordVoice
    /// User types the object label and picks its kind.
    case enterLabel
}

// MARK: - ViewModel

/// State machine driving the "Add Object" flow:
/// choose photo → lift subject → confirm cutout → record voice → label → save.
///
/// Vision processing and AVFoundation recording happen in their own views;
/// they call back into this ViewModel via `didExtractCutout` / `didRecord`.
@Observable
@MainActor
final class CutoutPipelineViewModel {

    // MARK: Identity

    let profileId: UUID
    private let existingObject: SceneObject?

    // MARK: Step

    private(set) var step: CutoutPipelineStep = .choosePhoto

    // MARK: Intermediate data

    private(set) var cutoutImageData: Data?
    private(set) var audioData: Data?

    // MARK: User-editable fields (used in `enterLabel` step)

    var label: String = ""
    var kind: ObjectKind = .noun
    var ttsOverride: String = ""

    // MARK: Init

    init(profileId: UUID, existingObject: SceneObject?) {
        self.profileId = profileId
        self.existingObject = existingObject
        if let obj = existingObject {
            label = obj.label
            kind = obj.kind
            ttsOverride = obj.ttsOverride ?? ""
        }
    }

    // MARK: Derived

    var hasCutout: Bool { cutoutImageData != nil }
    var hasRecording: Bool { audioData != nil }

    // MARK: Transitions

    /// Called when Vision (or manual selection) produces a cutout PNG `Data`.
    func didExtractCutout(imageData: Data) {
        cutoutImageData = imageData
        step = .confirmCutout
    }

    /// User approves the cutout; advance to voice recording.
    func confirmCutout() {
        guard step == .confirmCutout else { return }
        step = .recordVoice
    }

    /// User wants to retake the photo; clear cutout and return to step 1.
    func retakeCutout() {
        cutoutImageData = nil
        step = .choosePhoto
    }

    /// User recorded a voice clip; advance to label entry.
    func didRecord(audioData: Data) {
        self.audioData = audioData
        step = .enterLabel
    }

    /// User chose to skip recording; advance to label entry without audio.
    func skipRecording() {
        audioData = nil
        step = .enterLabel
    }

    // MARK: Build result

    /// Assembles the final `SceneObject` from collected data.
    /// Returns `nil` if the label is empty (invalid).
    /// Callers are responsible for persisting cutout/audio `Data` to disk
    /// and updating the returned object's `imageAssetName` / `audioAssetName`.
    func buildObject() -> SceneObject? {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var obj = existingObject ?? SceneObject(profileId: profileId, label: "", kind: .noun)
        obj.label = trimmed
        obj.kind = kind
        obj.ttsOverride = ttsOverride.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : ttsOverride.trimmingCharacters(in: .whitespaces)
        return obj
    }
}
