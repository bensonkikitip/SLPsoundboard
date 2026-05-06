import Foundation

/// A communication board: one background image + zero or more Placements and Hotspots.
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

    // MARK: Hotspots

    /// Labeled rectangular tap regions drawn directly on the background photo.
    /// Decoded with `decodeIfPresent` so scenes saved before hotspots were
    /// introduced continue to load without error.
    var hotspots: [SceneHotspot]

    // MARK: Init

    init(
        id: UUID = UUID(),
        profileId: UUID,
        name: String,
        backgroundAssetName: String? = nil,
        placements: [Placement] = [],
        hotspots: [SceneHotspot] = []
    ) {
        self.id = id
        self.profileId = profileId
        self.name = name
        self.backgroundAssetName = backgroundAssetName
        self.placements = placements
        self.hotspots = hotspots
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id, profileId, name, backgroundAssetName, placements, hotspots
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(UUID.self, forKey: .id)
        profileId           = try c.decode(UUID.self, forKey: .profileId)
        name                = try c.decode(String.self, forKey: .name)
        backgroundAssetName = try c.decodeIfPresent(String.self, forKey: .backgroundAssetName)
        placements          = try c.decode([Placement].self, forKey: .placements)
        hotspots            = try c.decodeIfPresent([SceneHotspot].self, forKey: .hotspots) ?? []
    }

    // MARK: Equatable

    static func == (lhs: SceneTalkScene, rhs: SceneTalkScene) -> Bool {
        lhs.id == rhs.id
    }
}
