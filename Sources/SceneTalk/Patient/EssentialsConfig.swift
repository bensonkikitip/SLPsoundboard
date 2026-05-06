import Foundation
import SwiftUI

// MARK: - EssentialColor

/// Semantic color palette for Essentials bar items.
/// Stored as a raw string so it survives Codable round-trips; missing keys default to `.gray`.
enum EssentialColor: String, Codable, Sendable, CaseIterable {
    case green, red, orange, blue, teal, purple, cyan, yellow, gray

    var color: Color {
        switch self {
        case .green:  return Color(red: 0.18, green: 0.72, blue: 0.30)   // vivid green
        case .red:    return Color(red: 0.93, green: 0.23, blue: 0.23)   // vivid red
        case .orange: return Color(red: 0.98, green: 0.52, blue: 0.10)   // warm orange
        case .blue:   return Color(red: 0.18, green: 0.50, blue: 0.95)   // royal blue
        case .teal:   return Color(red: 0.15, green: 0.68, blue: 0.75)   // medical teal
        case .purple: return Color(red: 0.62, green: 0.32, blue: 0.90)   // soft purple
        case .cyan:   return Color(red: 0.22, green: 0.80, blue: 0.95)   // ice cyan
        case .yellow: return Color(red: 0.98, green: 0.78, blue: 0.08)   // warm yellow
        case .gray:   return Color.secondary
        }
    }
}

// MARK: - EssentialsBarPosition

/// Which edge of the screen the Essentials bar appears on.
/// Set per-profile in Admin settings to accommodate hand dominance / visual-field deficits.
enum EssentialsBarPosition: String, Codable, CaseIterable, Sendable {
    case top
    case bottom
    case leading   // left in LTR
    case trailing  // right in LTR
}

// MARK: - EssentialItem

/// A single item in the Essentials bar.
struct EssentialItem: Identifiable, Equatable, Codable, Sendable {

    let id: UUID
    var label: String
    /// Text spoken by TTS when tapped. Defaults to `label` if not set separately.
    var ttsText: String
    /// SF Symbol name shown alongside (or instead of) a cutout image.
    var systemImageName: String
    /// Optional custom voice clip file name (documents directory).
    var audioAssetName: String?
    /// Icon + background accent color. Missing from old saves defaults to `.gray`.
    var tintColor: EssentialColor

    init(
        id: UUID = UUID(),
        label: String,
        ttsText: String? = nil,
        systemImageName: String,
        audioAssetName: String? = nil,
        tintColor: EssentialColor = .gray
    ) {
        self.id = id
        self.label = label
        self.ttsText = ttsText ?? label
        self.systemImageName = systemImageName
        self.audioAssetName = audioAssetName
        self.tintColor = tintColor
    }

    // MARK: Codable — manual decoder so `tintColor` defaults to .gray for old saves

    private enum CodingKeys: String, CodingKey {
        case id, label, ttsText, systemImageName, audioAssetName, tintColor
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,   forKey: .id)
        label          = try c.decode(String.self, forKey: .label)
        ttsText        = try c.decode(String.self, forKey: .ttsText)
        systemImageName = try c.decode(String.self, forKey: .systemImageName)
        audioAssetName = try c.decodeIfPresent(String.self,         forKey: .audioAssetName)
        tintColor      = try c.decodeIfPresent(EssentialColor.self, forKey: .tintColor) ?? .gray
    }

    static func == (lhs: EssentialItem, rhs: EssentialItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - EssentialsConfig

/// The per-profile configuration for the persistent Essentials bar.
struct EssentialsConfig: Codable, Sendable {

    var items: [EssentialItem]
    var position: EssentialsBarPosition

    init(items: [EssentialItem], position: EssentialsBarPosition = .top) {
        self.items = items
        self.position = position
    }

    // MARK: - Language-aware defaults

    /// The default Essentials bar for a given language.
    /// These represent the minimum viable set for hospital communication.
    static func `default`(language: Language) -> EssentialsConfig {
        EssentialsConfig(items: defaultItems(for: language), position: .top)
    }

    // MARK: Private

    private static func defaultItems(for language: Language) -> [EssentialItem] {
        switch language {
        case .english:
            return [
                EssentialItem(label: "Yes",      ttsText: "Yes",                   systemImageName: "checkmark.circle.fill", tintColor: .green),
                EssentialItem(label: "No",       ttsText: "No",                    systemImageName: "xmark.circle.fill",     tintColor: .red),
                EssentialItem(label: "Pain",     ttsText: "I am in pain",          systemImageName: "bolt.heart.fill",       tintColor: .red),
                EssentialItem(label: "Help",     ttsText: "I need help",           systemImageName: "hand.raised.fill",      tintColor: .orange),
                EssentialItem(label: "Nurse",    ttsText: "Please call the nurse", systemImageName: "stethoscope",           tintColor: .teal),
                EssentialItem(label: "Water",    ttsText: "I need water",          systemImageName: "drop.fill",             tintColor: .blue),
                EssentialItem(label: "Bathroom", ttsText: "I need the bathroom",   systemImageName: "toilet.fill",           tintColor: .purple),
                EssentialItem(label: "Cold",     ttsText: "I am cold",             systemImageName: "thermometer.snowflake", tintColor: .cyan),
                EssentialItem(label: "Hot",      ttsText: "I am hot",              systemImageName: "thermometer.sun.fill",  tintColor: .orange),
            ]
        case .spanish:
            return [
                EssentialItem(label: "Sí",        ttsText: "Sí",                                   systemImageName: "checkmark.circle.fill", tintColor: .green),
                EssentialItem(label: "No",        ttsText: "No",                                   systemImageName: "xmark.circle.fill",     tintColor: .red),
                EssentialItem(label: "Dolor",     ttsText: "Tengo dolor",                          systemImageName: "bolt.heart.fill",       tintColor: .red),
                EssentialItem(label: "Ayuda",     ttsText: "Necesito ayuda",                       systemImageName: "hand.raised.fill",      tintColor: .orange),
                EssentialItem(label: "Enfermera", ttsText: "Por favor llame a la enfermera",       systemImageName: "stethoscope",           tintColor: .teal),
                EssentialItem(label: "Agua",      ttsText: "Necesito agua",                        systemImageName: "drop.fill",             tintColor: .blue),
                EssentialItem(label: "Baño",      ttsText: "Necesito el baño",                     systemImageName: "toilet.fill",           tintColor: .purple),
                EssentialItem(label: "Frío",      ttsText: "Tengo frío",                           systemImageName: "thermometer.snowflake", tintColor: .cyan),
                EssentialItem(label: "Calor",     ttsText: "Tengo calor",                          systemImageName: "thermometer.sun.fill",  tintColor: .orange),
            ]
        }
    }
}
