import Foundation

/// A single instance of a `SceneObject` positioned within a `SceneTalkScene`.
///
/// Coordinates are **normalised 0…1** relative to the scene's background image
/// dimensions, so layouts survive screen-size changes and orientation.
///
/// `objectId` is a foreign-key reference into the Profile's Object Library.
/// Editing the referenced Object (label, audio, image) propagates automatically
/// because Placements carry no content of their own.
struct Placement: Identifiable, Equatable, Codable, Sendable {

    let id: UUID
    /// The Object this Placement references.
    let objectId: UUID
    /// The Scene this Placement belongs to.
    let sceneId: UUID

    // MARK: Geometry (normalised 0…1)

    /// Horizontal position of the leading edge, as a fraction of background width.
    var x: Double
    /// Vertical position of the top edge, as a fraction of background height.
    var y: Double
    /// Width as a fraction of background width.
    var width: Double
    /// Height as a fraction of background height.
    var height: Double

    /// Draw order — higher values appear on top.
    var zIndex: Int

    // MARK: Init

    init(
        id: UUID = UUID(),
        objectId: UUID,
        sceneId: UUID,
        x: Double,
        y: Double,
        width: Double = 0.12,
        height: Double = 0.12,
        zIndex: Int = 0
    ) {
        self.id = id
        self.objectId = objectId
        self.sceneId = sceneId
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.zIndex = zIndex
    }

    // MARK: Equatable

    static func == (lhs: Placement, rhs: Placement) -> Bool {
        lhs.id == rhs.id
    }
}
