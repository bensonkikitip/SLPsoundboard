import Foundation

/// Seed data for the Hospital starter scene provisioned on first launch.
///
/// V2 (noun-only): The Hospital Room scene contains exclusively physical noun
/// objects (Bed, TV, Toilet, Cup, IV pole, Chair, Window, Clock, Pillow, Nurse
/// call button). Tapping a noun speaks the noun via TTS — `ttsOverride: nil` so
/// `SceneObject.ttsText` falls back to `label`. Action vocabulary (Pain, Help,
/// Nurse, Water, Bathroom, Cold, Hot) lives only in the Essentials bar.
///
/// Each object's `imageAssetName` carries an artwork key prefixed with `"art:"`
/// (e.g. `"art:bed"`). `SceneObjectArtworkView` reads these keys and renders
/// custom SwiftUI shapes per prop. SF symbol fallback ("sfsymbol:...") is still
/// honored for backward compatibility with previously-seeded data.
enum HospitalStarter {

    struct SeedResult {
        let objects: [SceneObject]
        let scenes: [SceneTalkScene]
    }

    /// Generate the complete starter content for `profileId` in `language`.
    static func seed(profileId: UUID, language: Language) -> SeedResult {
        switch language {
        case .english: return seedEnglish(profileId: profileId)
        case .spanish: return seedSpanish(profileId: profileId)
        }
    }

    // MARK: - English seed

    private static func seedEnglish(profileId: UUID) -> SeedResult {
        let bed       = noun(profileId, "Bed",        "art:bed")
        let pillow    = noun(profileId, "Pillow",     "art:pillow")
        // Disambiguate "TV" (often read letter-by-letter) and "IV pole" so TTS
        // pronounces them naturally / unambiguously.
        let tv        = noun(profileId, "TV",         "art:tv",      tts: "Television")
        let ivPole    = noun(profileId, "IV pole",    "art:ivpole",  tts: "I V pole")
        let cup       = noun(profileId, "Cup",        "art:cup")
        let chair     = noun(profileId, "Chair",      "art:chair")
        let window    = noun(profileId, "Window",     "art:window")
        let clock     = noun(profileId, "Clock",      "art:clock")
        let nurseCall = noun(profileId, "Nurse call", "art:nurseCall")

        let allObjects = [bed, pillow, tv, ivPole, cup, chair, window, clock, nurseCall]

        // Hospital room from the foot of the bed (landscape iPad):
        //   • Clock upper-left      • Window upper-center      • TV upper-right
        //   • Nurse call at headboard (left side of bed)
        //   • Bed in centre           • Pillow at the head of bed
        //   • IV pole right of bed    • Cup on right nightstand
        //   • Chair lower-left
        let sceneId = UUID()
        let placements: [Placement] = [
            Placement(objectId: clock.id,     sceneId: sceneId, x: 0.10, y: 0.10, width: 0.08, height: 0.08, zIndex: 1),
            Placement(objectId: window.id,    sceneId: sceneId, x: 0.40, y: 0.06, width: 0.16, height: 0.18, zIndex: 1),
            Placement(objectId: tv.id,        sceneId: sceneId, x: 0.70, y: 0.10, width: 0.20, height: 0.16, zIndex: 1),
            Placement(objectId: nurseCall.id, sceneId: sceneId, x: 0.20, y: 0.32, width: 0.06, height: 0.10, zIndex: 2),
            Placement(objectId: pillow.id,    sceneId: sceneId, x: 0.36, y: 0.36, width: 0.10, height: 0.08, zIndex: 3),
            Placement(objectId: bed.id,       sceneId: sceneId, x: 0.32, y: 0.42, width: 0.36, height: 0.30, zIndex: 1),
            Placement(objectId: ivPole.id,    sceneId: sceneId, x: 0.76, y: 0.32, width: 0.07, height: 0.30, zIndex: 1),
            Placement(objectId: cup.id,       sceneId: sceneId, x: 0.85, y: 0.50, width: 0.08, height: 0.10, zIndex: 1),
            Placement(objectId: chair.id,     sceneId: sceneId, x: 0.06, y: 0.62, width: 0.14, height: 0.20, zIndex: 1),
        ]

        let hospitalRoom = SceneTalkScene(
            id: sceneId,
            profileId: profileId,
            name: "Hospital Room",
            backgroundAssetName: "procedural:hospital",
            placements: placements
        )
        return SeedResult(objects: allObjects, scenes: [hospitalRoom])
    }

    // MARK: - Spanish seed

    private static func seedSpanish(profileId: UUID) -> SeedResult {
        let bed       = noun(profileId, "Cama",            "art:bed")
        let pillow    = noun(profileId, "Almohada",        "art:pillow")
        let tv        = noun(profileId, "Televisión",      "art:tv")
        let ivPole    = noun(profileId, "Suero",           "art:ivpole")
        let cup       = noun(profileId, "Taza",            "art:cup")
        let chair     = noun(profileId, "Silla",           "art:chair")
        let window    = noun(profileId, "Ventana",         "art:window")
        let clock     = noun(profileId, "Reloj",           "art:clock")
        let nurseCall = noun(profileId, "Botón enfermera", "art:nurseCall")

        let allObjects = [bed, pillow, tv, ivPole, cup, chair, window, clock, nurseCall]

        let sceneId = UUID()
        let placements: [Placement] = [
            Placement(objectId: clock.id,     sceneId: sceneId, x: 0.10, y: 0.10, width: 0.08, height: 0.08, zIndex: 1),
            Placement(objectId: window.id,    sceneId: sceneId, x: 0.40, y: 0.06, width: 0.16, height: 0.18, zIndex: 1),
            Placement(objectId: tv.id,        sceneId: sceneId, x: 0.70, y: 0.10, width: 0.20, height: 0.16, zIndex: 1),
            Placement(objectId: nurseCall.id, sceneId: sceneId, x: 0.20, y: 0.32, width: 0.06, height: 0.10, zIndex: 2),
            Placement(objectId: pillow.id,    sceneId: sceneId, x: 0.36, y: 0.36, width: 0.10, height: 0.08, zIndex: 3),
            Placement(objectId: bed.id,       sceneId: sceneId, x: 0.32, y: 0.42, width: 0.36, height: 0.30, zIndex: 1),
            Placement(objectId: ivPole.id,    sceneId: sceneId, x: 0.76, y: 0.32, width: 0.07, height: 0.30, zIndex: 1),
            Placement(objectId: cup.id,       sceneId: sceneId, x: 0.85, y: 0.50, width: 0.08, height: 0.10, zIndex: 1),
            Placement(objectId: chair.id,     sceneId: sceneId, x: 0.06, y: 0.62, width: 0.14, height: 0.20, zIndex: 1),
        ]

        let habitacion = SceneTalkScene(
            id: sceneId,
            profileId: profileId,
            name: "Habitación Hospital",
            backgroundAssetName: "procedural:hospital",
            placements: placements
        )
        return SeedResult(objects: allObjects, scenes: [habitacion])
    }

    // MARK: - Helpers

    /// Build a noun object with an artwork key as `imageAssetName`. By default
    /// taps speak the label; pass `tts:` to override pronunciation (e.g. force
    /// "Television" instead of letter-by-letter "TV").
    private static func noun(
        _ profileId: UUID,
        _ label: String,
        _ artworkKey: String,
        tts ttsOverride: String? = nil
    ) -> SceneObject {
        var object = SceneObject(
            profileId: profileId,
            label: label,
            kind: .noun,
            ttsOverride: ttsOverride
        )
        object.imageAssetName = artworkKey
        return object
    }
}

// MARK: - SceneObject artwork-key extension

extension SceneObject {

    /// Custom artwork key (e.g. "bed", "tv", "toilet"), or nil if this object's
    /// `imageAssetName` is not an artwork key. Stored as `"art:<key>"`.
    var artworkKey: String? {
        guard let name = imageAssetName, name.hasPrefix("art:") else { return nil }
        return String(name.dropFirst("art:".count))
    }

    /// SF Symbol name stored on the object (legacy seed format).
    /// Stored as `"sfsymbol:<name>"`. Kept for backward compatibility with
    /// scenes saved before the V2 noun-only seed.
    var systemImageName: String? {
        guard let name = imageAssetName, name.hasPrefix("sfsymbol:") else { return nil }
        return String(name.dropFirst("sfsymbol:".count))
    }

    /// Returns a copy of this object with the given SF Symbol attached
    /// (legacy helper kept for HomeStarter).
    func withSystemImageName(_ name: String) -> SceneObject {
        var copy = self
        copy.imageAssetName = "sfsymbol:\(name)"
        return copy
    }
}
