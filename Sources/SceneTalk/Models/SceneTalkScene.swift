import Foundation

/// A communication board: one background image + zero or more Placements.
///
/// Naming: `SceneTalkScene` (not `Scene`) to avoid collision with SwiftUI's `Scene`.
struct SceneTalkScene: Identifiable, Equatable, Codable, Sendable {

    // MARK: Identity

    let id: UUID
    let profileId: UUID

    // MARK: Content

    var name: String

    /// File name of the background photo stored in the app's documents directory.
    /// `nil` until a background has been assigned in the Scene editor.
    var backgroundAssetName: String?

    // MARK: Placements

    /// Ordered list of Placements in this Scene.
    /// Array order does not imply rendering order — use `Placement.zIndex`.
    var placements: [Placement]

    // MARK: Init

    init(
        id: UUID = UUID(),
        profileId: UUID,
        name: String,
        backgroundAssetName: String? = nil,
        placements: [Placement] = []
    ) {
        self.id = id
        self.profileId = profileId
        self.name = name
        self.backgroundAssetName = backgroundAssetName
        self.placements = placements
    }

    // MARK: Equatable

    static func == (lhs: SceneTalkScene, rhs: SceneTalkScene) -> Bool {
        lhs.id == rhs.id
    }
}
