import Foundation
import CoreGraphics

// MARK: - Hit-target size

/// Per-profile hit-target size for tappable objects in Patient mode.
/// Larger sizes benefit patients with motor impairments or visual field deficits.
enum HitTargetSize: String, Codable, CaseIterable, Sendable {
    case medium     = "M"
    case large      = "L"
    case extraLarge = "XL"

    /// The minimum tap-target dimension in points.
    var points: CGFloat {
        switch self {
        case .medium:     return 88
        case .large:      return 110
        case .extraLarge: return 132
        }
    }

    /// A localised display name.
    var displayName: String {
        switch self {
        case .medium:     return "M"
        case .large:      return "L"
        case .extraLarge: return "XL"
        }
    }
}

// MARK: - Layout preferences

/// Per-profile layout configuration stored inside `Profile`.
/// All fields have sensible defaults — no configuration required on day 1.
struct LayoutPreferences: Codable, Equatable, Sendable {

    /// Minimum touch target size for scene-object tiles.
    var hitTargetSize: HitTargetSize = .medium

    /// Which edge of the screen the Essentials bar occupies.
    var essentialsBarPosition: EssentialsBarPosition = .bottom

    init(
        hitTargetSize: HitTargetSize = .medium,
        essentialsBarPosition: EssentialsBarPosition = .bottom
    ) {
        self.hitTargetSize = hitTargetSize
        self.essentialsBarPosition = essentialsBarPosition
    }
}
