import Foundation

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

    init(
        id: UUID = UUID(),
        label: String,
        ttsText: String? = nil,
        systemImageName: String,
        audioAssetName: String? = nil
    ) {
        self.id = id
        self.label = label
        self.ttsText = ttsText ?? label
        self.systemImageName = systemImageName
        self.audioAssetName = audioAssetName
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
                EssentialItem(label: "Yes",      ttsText: "Yes",               systemImageName: "checkmark.circle.fill"),
                EssentialItem(label: "No",       ttsText: "No",                systemImageName: "xmark.circle.fill"),
                EssentialItem(label: "Pain",     ttsText: "I am in pain",      systemImageName: "bolt.heart.fill"),
                EssentialItem(label: "Help",     ttsText: "I need help",       systemImageName: "hand.raised.fill"),
                EssentialItem(label: "Nurse",    ttsText: "Please call the nurse", systemImageName: "stethoscope"),
                EssentialItem(label: "Water",    ttsText: "I need water",      systemImageName: "drop.fill"),
                EssentialItem(label: "Bathroom", ttsText: "I need the bathroom", systemImageName: "toilet.fill"),
                EssentialItem(label: "Cold",     ttsText: "I am cold",         systemImageName: "thermometer.snowflake"),
                EssentialItem(label: "Hot",      ttsText: "I am hot",          systemImageName: "thermometer.sun.fill"),
            ]
        case .spanish:
            return [
                EssentialItem(label: "Sí",       ttsText: "Sí",                systemImageName: "checkmark.circle.fill"),
                EssentialItem(label: "No",       ttsText: "No",                systemImageName: "xmark.circle.fill"),
                EssentialItem(label: "Dolor",    ttsText: "Tengo dolor",       systemImageName: "bolt.heart.fill"),
                EssentialItem(label: "Ayuda",    ttsText: "Necesito ayuda",    systemImageName: "hand.raised.fill"),
                EssentialItem(label: "Enfermera", ttsText: "Por favor llame a la enfermera", systemImageName: "stethoscope"),
                EssentialItem(label: "Agua",     ttsText: "Necesito agua",     systemImageName: "drop.fill"),
                EssentialItem(label: "Baño",     ttsText: "Necesito el baño",  systemImageName: "toilet.fill"),
                EssentialItem(label: "Frío",     ttsText: "Tengo frío",        systemImageName: "thermometer.snowflake"),
                EssentialItem(label: "Calor",    ttsText: "Tengo calor",       systemImageName: "thermometer.sun.fill"),
            ]
        }
    }
}
