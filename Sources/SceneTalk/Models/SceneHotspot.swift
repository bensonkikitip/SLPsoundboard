import Foundation

/// A labeled rectangular tap region drawn directly on a scene's background photo.
///
/// Hotspots complement the object-placement system for environments where the user
/// wants to label areas of a real photo (e.g. "stove", "sink" on a kitchen photo)
/// without building a full object library.
///
/// All coordinates are **normalised 0–1** relative to the background image bounds,
/// matching the `Placement` convention so layouts survive orientation changes.
struct SceneHotspot: Identifiable, Equatable, Codable, Sendable {

    // MARK: Identity

    let id: UUID
    let sceneId: UUID

    // MARK: Content

    var label: String

    // MARK: Geometry (normalised 0…1)

    var x: Double        // left edge
    var y: Double        // top edge
    var width: Double
    var height: Double

    // MARK: Audio

    /// Relative path to a recorded voice clip, e.g. `"<profileId>/audio/<id>.m4a"`.
    /// `nil` means TTS will be used on tap.
    var audioAssetName: String?

    /// Override text fed to TTS. Falls back to `label` when nil.
    var ttsOverride: String?

    var ttsText: String { ttsOverride ?? label }

    // MARK: Init

    init(
        id: UUID = UUID(),
        sceneId: UUID,
        label: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        audioAssetName: String? = nil,
        ttsOverride: String? = nil
    ) {
        self.id = id
        self.sceneId = sceneId
        self.label = label
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.audioAssetName = audioAssetName
        self.ttsOverride = ttsOverride
    }
}
