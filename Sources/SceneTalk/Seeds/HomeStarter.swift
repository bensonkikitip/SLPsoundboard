import Foundation

/// Seed data for the Home starter scenes provisioned on first launch (home mode).
/// Provides a Kitchen scene and a Living Room scene with contextually-placed objects.
enum HomeStarter {

    /// Generate the complete starter content for `profileId` in `language`.
    static func seed(profileId: UUID, language: Language) -> HospitalStarter.SeedResult {
        switch language {
        case .english: return seedEnglish(profileId: profileId)
        case .spanish: return seedSpanish(profileId: profileId)
        }
    }

    // MARK: - English seed

    private static func seedEnglish(profileId: UUID) -> HospitalStarter.SeedResult {

        // ── Kitchen objects ──────────────────────────────────────────────────
        let hungry      = makeObject(profileId, "I'm hungry",      .phraseIntent, "I am hungry",              "fork.knife")
        let thirsty     = makeObject(profileId, "I'm thirsty",     .phraseIntent, "I am thirsty",             "drop.fill")
        let tooHot      = makeObject(profileId, "Too hot",         .phraseIntent, "I am too hot",             "thermometer.sun.fill")
        let tooCold     = makeObject(profileId, "Too cold",        .phraseIntent, "I am too cold",            "thermometer.snowflake")
        let medicine    = makeObject(profileId, "Medicine please", .phraseIntent, "I need my medicine",       "pills.fill")
        let callFamily  = makeObject(profileId, "Call family",     .phraseIntent, "Please call the family",   "phone.fill")
        // Noun objects
        let fridge      = makeObject(profileId, "Fridge",  .noun, nil, "refrigerator.fill")
        let chair       = makeObject(profileId, "Chair",   .noun, nil, "chair.fill")

        // ── Living room objects ──────────────────────────────────────────────
        let tvPlease    = makeObject(profileId, "TV please",    .phraseIntent, "Can you turn on the TV",      "tv.fill")
        let tooLoud     = makeObject(profileId, "Too loud",     .phraseIntent, "It is too loud",              "speaker.wave.3.fill")
        let tooQuiet    = makeObject(profileId, "Too quiet",    .phraseIntent, "Can you turn it up",          "speaker.fill")
        let needBlanket = makeObject(profileId, "Need blanket", .phraseIntent, "I need a blanket",            "bed.double.fill")
        let tooBright   = makeObject(profileId, "Too bright",   .phraseIntent, "It is too bright in here",   "sun.max.fill")
        let tooDark     = makeObject(profileId, "Too dark",     .phraseIntent, "It is too dark in here",     "moon.fill")
        // Noun objects
        let couch       = makeObject(profileId, "Couch",   .noun, nil, "sofa.fill")
        let remote      = makeObject(profileId, "Remote",  .noun, nil, "rectangle.fill.on.rectangle.fill")

        let allObjects = [hungry, thirsty, tooHot, tooCold, medicine, callFamily, fridge, chair,
                          tvPlease, tooLoud, tooQuiet, needBlanket, tooBright, tooDark, couch, remote]

        // ── Kitchen scene — contextual layout ────────────────────────────────
        // From the kitchen doorway:
        //   sink upper-left, stove upper-center, fridge right edge,
        //   table center, window light upper-right
        let kitchenId = UUID()
        let kitchenPlacements: [Placement] = [
            // Hungry — at the table center
            Placement(objectId: hungry.id,      sceneId: kitchenId, x: 0.38, y: 0.50, width: 0.22, height: 0.22, zIndex: 1),
            // Thirsty — near sink (upper-left)
            Placement(objectId: thirsty.id,     sceneId: kitchenId, x: 0.06, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            // Medicine — on the counter (upper-center)
            Placement(objectId: medicine.id,    sceneId: kitchenId, x: 0.36, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            // Call family — upper-right
            Placement(objectId: callFamily.id,  sceneId: kitchenId, x: 0.68, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            // Too hot / too cold — lower area
            Placement(objectId: tooHot.id,      sceneId: kitchenId, x: 0.06, y: 0.68, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: tooCold.id,     sceneId: kitchenId, x: 0.28, y: 0.68, width: 0.20, height: 0.20, zIndex: 1),
            // Ambient nouns
            Placement(objectId: fridge.id,      sceneId: kitchenId, x: 0.84, y: 0.30, width: 0.12, height: 0.22, zIndex: 0),
            Placement(objectId: chair.id,       sceneId: kitchenId, x: 0.50, y: 0.72, width: 0.12, height: 0.16, zIndex: 0),
        ]

        let kitchen = SceneTalkScene(
            id: kitchenId,
            profileId: profileId,
            name: "Kitchen",
            backgroundAssetName: "procedural:kitchen",
            placements: kitchenPlacements
        )

        // ── Living room scene — contextual layout ────────────────────────────
        // TV wall upper-left, couch center-lower, lamp/window upper-right
        let livingId = UUID()
        let livingPlacements: [Placement] = [
            // TV — upper-left (wall-mounted)
            Placement(objectId: tvPlease.id,    sceneId: livingId, x: 0.06, y: 0.08, width: 0.22, height: 0.22, zIndex: 1),
            // Too loud — next to TV
            Placement(objectId: tooLoud.id,     sceneId: livingId, x: 0.06, y: 0.35, width: 0.20, height: 0.20, zIndex: 1),
            // Too quiet — next to TV other side
            Placement(objectId: tooQuiet.id,    sceneId: livingId, x: 0.28, y: 0.35, width: 0.20, height: 0.20, zIndex: 1),
            // Need blanket — near couch center
            Placement(objectId: needBlanket.id, sceneId: livingId, x: 0.38, y: 0.60, width: 0.22, height: 0.22, zIndex: 1),
            // Too bright / too dark — near window (upper-right)
            Placement(objectId: tooBright.id,   sceneId: livingId, x: 0.70, y: 0.08, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: tooDark.id,     sceneId: livingId, x: 0.70, y: 0.32, width: 0.20, height: 0.20, zIndex: 1),
            // Ambient nouns
            Placement(objectId: couch.id,       sceneId: livingId, x: 0.38, y: 0.72, width: 0.24, height: 0.16, zIndex: 0),
            Placement(objectId: remote.id,      sceneId: livingId, x: 0.62, y: 0.65, width: 0.10, height: 0.10, zIndex: 0),
        ]

        let livingRoom = SceneTalkScene(
            id: livingId,
            profileId: profileId,
            name: "Living Room",
            backgroundAssetName: "procedural:living",
            placements: livingPlacements
        )

        return HospitalStarter.SeedResult(objects: allObjects, scenes: [kitchen, livingRoom])
    }

    // MARK: - Spanish seed

    private static func seedSpanish(profileId: UUID) -> HospitalStarter.SeedResult {

        let hungry      = makeObject(profileId, "Tengo hambre",    .phraseIntent, "Tengo hambre",             "fork.knife")
        let thirsty     = makeObject(profileId, "Tengo sed",       .phraseIntent, "Tengo sed",                "drop.fill")
        let tooHot      = makeObject(profileId, "Tengo calor",     .phraseIntent, "Tengo calor",              "thermometer.sun.fill")
        let tooCold     = makeObject(profileId, "Tengo frío",      .phraseIntent, "Tengo frío",               "thermometer.snowflake")
        let medicine    = makeObject(profileId, "Medicina",        .phraseIntent, "Necesito mi medicina",     "pills.fill")
        let callFamily  = makeObject(profileId, "Llamar familia",  .phraseIntent, "Por favor llame a la familia", "phone.fill")
        let fridge      = makeObject(profileId, "Refrigerador",    .noun, nil, "refrigerator.fill")
        let chair       = makeObject(profileId, "Silla",           .noun, nil, "chair.fill")

        let tvPlease    = makeObject(profileId, "Prender la tele", .phraseIntent, "Puede prender la televisión", "tv.fill")
        let tooLoud     = makeObject(profileId, "Muy alto",        .phraseIntent, "Está muy alto",            "speaker.wave.3.fill")
        let tooQuiet    = makeObject(profileId, "Muy bajo",        .phraseIntent, "Puede subir el volumen",   "speaker.fill")
        let needBlanket = makeObject(profileId, "Necesito cobija", .phraseIntent, "Necesito una cobija",      "bed.double.fill")
        let tooBright   = makeObject(profileId, "Mucha luz",       .phraseIntent, "Hay mucha luz",            "sun.max.fill")
        let tooDark     = makeObject(profileId, "Poca luz",        .phraseIntent, "Hay poca luz",             "moon.fill")
        let couch       = makeObject(profileId, "Sofá",    .noun, nil, "sofa.fill")
        let remote      = makeObject(profileId, "Control", .noun, nil, "rectangle.fill.on.rectangle.fill")

        let allObjects = [hungry, thirsty, tooHot, tooCold, medicine, callFamily, fridge, chair,
                          tvPlease, tooLoud, tooQuiet, needBlanket, tooBright, tooDark, couch, remote]

        let kitchenId = UUID()
        let kitchenPlacements: [Placement] = [
            Placement(objectId: hungry.id,      sceneId: kitchenId, x: 0.38, y: 0.50, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: thirsty.id,     sceneId: kitchenId, x: 0.06, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: medicine.id,    sceneId: kitchenId, x: 0.36, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: callFamily.id,  sceneId: kitchenId, x: 0.68, y: 0.10, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: tooHot.id,      sceneId: kitchenId, x: 0.06, y: 0.68, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: tooCold.id,     sceneId: kitchenId, x: 0.28, y: 0.68, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: fridge.id,      sceneId: kitchenId, x: 0.84, y: 0.30, width: 0.12, height: 0.22, zIndex: 0),
            Placement(objectId: chair.id,       sceneId: kitchenId, x: 0.50, y: 0.72, width: 0.12, height: 0.16, zIndex: 0),
        ]

        let cocina = SceneTalkScene(
            id: kitchenId,
            profileId: profileId,
            name: "Cocina",
            backgroundAssetName: "procedural:kitchen",
            placements: kitchenPlacements
        )

        let livingId = UUID()
        let livingPlacements: [Placement] = [
            Placement(objectId: tvPlease.id,    sceneId: livingId, x: 0.06, y: 0.08, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: tooLoud.id,     sceneId: livingId, x: 0.06, y: 0.35, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: tooQuiet.id,    sceneId: livingId, x: 0.28, y: 0.35, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: needBlanket.id, sceneId: livingId, x: 0.38, y: 0.60, width: 0.22, height: 0.22, zIndex: 1),
            Placement(objectId: tooBright.id,   sceneId: livingId, x: 0.70, y: 0.08, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: tooDark.id,     sceneId: livingId, x: 0.70, y: 0.32, width: 0.20, height: 0.20, zIndex: 1),
            Placement(objectId: couch.id,       sceneId: livingId, x: 0.38, y: 0.72, width: 0.24, height: 0.16, zIndex: 0),
            Placement(objectId: remote.id,      sceneId: livingId, x: 0.62, y: 0.65, width: 0.10, height: 0.10, zIndex: 0),
        ]

        let sala = SceneTalkScene(
            id: livingId,
            profileId: profileId,
            name: "Sala",
            backgroundAssetName: "procedural:living",
            placements: livingPlacements
        )

        return HospitalStarter.SeedResult(objects: allObjects, scenes: [cocina, sala])
    }

    // MARK: - Helper

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
