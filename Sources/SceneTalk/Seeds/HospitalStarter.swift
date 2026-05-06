import Foundation

/// Seed data for the Hospital starter scene provisioned on first launch.
/// Contains intent-focused objects relevant to an inpatient hospital stay
/// plus ambient items. Stock cutouts use SF Symbol names (no image data yet).
/// Audio defaults to TTS; family/SLP replace with voice clips over time.
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
        // Phrase-intent objects
        let callNurse   = makeObject(profileId, "Call nurse",    .phraseIntent, "Please call the nurse",       "stethoscope")
        let needBath    = makeObject(profileId, "Need bathroom", .phraseIntent, "I need the bathroom",         "signpost.right.fill")
        let inPain      = makeObject(profileId, "I'm in pain",   .phraseIntent, "I am in pain",                "bolt.heart.fill")
        let adjustBed   = makeObject(profileId, "Adjust bed",    .phraseIntent, "Please adjust my bed",        "bed.double.fill")
        let needWater   = makeObject(profileId, "Need water",    .phraseIntent, "I need water",                "drop.fill")
        let needPillow  = makeObject(profileId, "Need pillow",   .phraseIntent, "I need a pillow",             "moon.zzz.fill")
        let tvPlease    = makeObject(profileId, "TV please",     .phraseIntent, "Can you turn on the TV",      "tv.fill")
        // Noun objects (ambient)
        let bed         = makeObject(profileId, "Bed",     .noun, nil, "bed.double")
        let waterCup    = makeObject(profileId, "Cup",     .noun, nil, "cup.and.saucer.fill")
        let ivPole      = makeObject(profileId, "IV pole", .noun, nil, "ivfluid.bag.fill")
        let famChair    = makeObject(profileId, "Chair",   .noun, nil, "chair.lounge.fill")

        let allObjects = [callNurse, needBath, inPain, adjustBed, needWater, needPillow, tvPlease,
                          bed, waterCup, ivPole, famChair]

        // Place the key phrase-intent objects in a 3-column layout
        let sceneId = UUID()
        let placements: [Placement] = [
            Placement(objectId: callNurse.id,  sceneId: sceneId, x: 0.08, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: inPain.id,     sceneId: sceneId, x: 0.40, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needBath.id,   sceneId: sceneId, x: 0.70, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needWater.id,  sceneId: sceneId, x: 0.08, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: adjustBed.id,  sceneId: sceneId, x: 0.40, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needPillow.id, sceneId: sceneId, x: 0.70, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: tvPlease.id,   sceneId: sceneId, x: 0.08, y: 0.72, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: waterCup.id,   sceneId: sceneId, x: 0.70, y: 0.72, width: 0.14, height: 0.14, zIndex: 0),
        ]

        let hospitalRoom = SceneTalkScene(
            id: sceneId,
            profileId: profileId,
            name: "Hospital Room",
            placements: placements
        )
        return SeedResult(objects: allObjects, scenes: [hospitalRoom])
    }

    // MARK: - Spanish seed

    private static func seedSpanish(profileId: UUID) -> SeedResult {
        let callNurse   = makeObject(profileId, "Llamar enfermera",  .phraseIntent, "Por favor llame a la enfermera", "stethoscope")
        let needBath    = makeObject(profileId, "Necesito el baño",  .phraseIntent, "Necesito ir al baño",            "signpost.right.fill")
        let inPain      = makeObject(profileId, "Tengo dolor",       .phraseIntent, "Tengo dolor",                    "bolt.heart.fill")
        let adjustBed   = makeObject(profileId, "Ajustar cama",      .phraseIntent, "Por favor ajuste mi cama",       "bed.double.fill")
        let needWater   = makeObject(profileId, "Necesito agua",     .phraseIntent, "Necesito agua",                  "drop.fill")
        let needPillow  = makeObject(profileId, "Necesito almohada", .phraseIntent, "Necesito una almohada",          "moon.zzz.fill")
        let tvPlease    = makeObject(profileId, "Prender la tele",   .phraseIntent, "Puede prender la televisión",    "tv.fill")
        let bed         = makeObject(profileId, "Cama",      .noun, nil, "bed.double")
        let waterCup    = makeObject(profileId, "Taza",      .noun, nil, "cup.and.saucer.fill")
        let ivPole      = makeObject(profileId, "Suero",     .noun, nil, "ivfluid.bag.fill")
        let famChair    = makeObject(profileId, "Silla",     .noun, nil, "chair.lounge.fill")

        let allObjects = [callNurse, needBath, inPain, adjustBed, needWater, needPillow, tvPlease,
                          bed, waterCup, ivPole, famChair]

        let sceneId = UUID()
        let placements: [Placement] = [
            Placement(objectId: callNurse.id,  sceneId: sceneId, x: 0.08, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: inPain.id,     sceneId: sceneId, x: 0.40, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needBath.id,   sceneId: sceneId, x: 0.70, y: 0.12, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needWater.id,  sceneId: sceneId, x: 0.08, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: adjustBed.id,  sceneId: sceneId, x: 0.40, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: needPillow.id, sceneId: sceneId, x: 0.70, y: 0.42, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: tvPlease.id,   sceneId: sceneId, x: 0.08, y: 0.72, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: waterCup.id,   sceneId: sceneId, x: 0.70, y: 0.72, width: 0.14, height: 0.14, zIndex: 0),
        ]

        let habitacion = SceneTalkScene(
            id: sceneId,
            profileId: profileId,
            name: "Habitación Hospital",
            placements: placements
        )
        return SeedResult(objects: allObjects, scenes: [habitacion])
    }

    // MARK: - Helpers

    private static func makeObject(
        _ profileId: UUID,
        _ label: String,
        _ kind: ObjectKind,
        _ ttsOverride: String?,
        _ systemImageName: String
    ) -> SceneObject {
        SceneObject(
            profileId: profileId,
            label: label,
            kind: kind,
            ttsOverride: ttsOverride
        ).withSystemImageName(systemImageName)
    }
}

// MARK: - SceneObject extension for seed convenience

extension SceneObject {
    /// SF Symbol name stored on the object for the patient-mode placeholder icon
    /// (used until a real cutout is authored).
    var systemImageName: String? {
        // Stored as a special imageAssetName prefix: "sfsymbol:<name>"
        guard let name = imageAssetName, name.hasPrefix("sfsymbol:") else { return nil }
        return String(name.dropFirst("sfsymbol:".count))
    }

    func withSystemImageName(_ name: String) -> SceneObject {
        var copy = self
        copy.imageAssetName = "sfsymbol:\(name)"
        return copy
    }
}
