import Foundation

// MARK: - ObjectKind

/// Whether an Object represents a physical thing or a communicative need.
enum ObjectKind: String, Codable, CaseIterable, Sendable {
    /// A physical thing (apple, bed, water cup, restroom sign).
    case noun
    /// A communicative need or action ("Call nurse", "I'm in pain", "Need bathroom").
    case phraseIntent
}

// MARK: - SceneObject

/// The reusable unit of communication content in an Object Library.
///
/// A SceneObject exists once per Profile and can be *placed* into multiple
/// Scenes via `Placement`.  Editing an Object's audio or image propagates to
/// all Scenes that contain a Placement for it.
///
/// Naming: `SceneObject` (not `Object`) to avoid collision with `Swift.AnyObject`.
struct SceneObject: Identifiable, Equatable, Codable, Sendable {

    // MARK: Identity

    let id: UUID
    /// The Profile this Object belongs to.
    let profileId: UUID

    // MARK: Content

    /// Short display label shown on screen when tapped (e.g. "Apple", "Call nurse").
    var label: String

    /// Semantic kind — noun or phrase-intent.
    var kind: ObjectKind

    /// File name of the cutout PNG stored in the app's documents directory.
    /// `nil` until the cutout pipeline produces an image.
    var imageAssetName: String?

    /// File name of the recorded voice clip (AAC/m4a) in documents directory.
    /// `nil` until family records audio. TTS is used as fallback.
    var audioAssetName: String?

    /// Optional override for TTS speech text.
    /// When `nil`, `ttsText` returns `label`.
    /// Use when the label is abbreviated and TTS should say the full phrase.
    var ttsOverride: String?

    // MARK: Init

    init(
        id: UUID = UUID(),
        profileId: UUID,
        label: String,
        kind: ObjectKind,
        imageAssetName: String? = nil,
        audioAssetName: String? = nil,
        ttsOverride: String? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.label = label
        self.kind = kind
        self.imageAssetName = imageAssetName
        self.audioAssetName = audioAssetName
        self.ttsOverride = ttsOverride
    }

    // MARK: Derived

    /// The text spoken by TTS when no voice clip is present.
    var ttsText: String { ttsOverride ?? label }

    /// Whether a family-recorded voice clip is available.
    var hasVoiceClip: Bool { audioAssetName != nil }

    // MARK: Equatable

    static func == (lhs: SceneObject, rhs: SceneObject) -> Bool {
        lhs.id == rhs.id
    }
}
