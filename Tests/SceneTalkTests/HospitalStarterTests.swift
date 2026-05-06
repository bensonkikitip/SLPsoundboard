import XCTest
@testable import SceneTalk

/// Tests that the Hospital starter seed produces the expected content for each language.
final class HospitalStarterTests: XCTestCase {

    // MARK: - English

    func test_englishStarter_hasHospitalRoomScene() {
        let profileId = UUID()
        let result = HospitalStarter.seed(profileId: profileId, language: .english)
        let sceneNames = result.scenes.map(\.name)
        XCTAssertTrue(sceneNames.contains("Hospital Room"), "Must include a Hospital Room scene")
    }

    func test_englishStarter_includesCallNurseObject() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let labels = result.objects.map(\.label)
        XCTAssertTrue(labels.contains("Call nurse"))
    }

    func test_englishStarter_includesNeedBathroomObject() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let labels = result.objects.map(\.label)
        XCTAssertTrue(labels.contains("Need bathroom"))
    }

    func test_englishStarter_includesImInPainObject() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let labels = result.objects.map(\.label)
        XCTAssertTrue(labels.contains("I'm in pain"))
    }

    func test_englishStarter_includesRestroomSignObject() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let sfImages = result.objects.compactMap(\.systemImageName)
        XCTAssertTrue(sfImages.contains("signpost.right.fill"), "Restroom sign object must be present")
    }

    func test_englishStarter_allPhraseIntentObjects_arePhraseIntent() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let intents = result.objects.filter { $0.kind == .phraseIntent }
        XCTAssertFalse(intents.isEmpty, "Starter must contain phrase-intent objects")
    }

    func test_englishStarter_hospitalRoom_hasObjectPlacements() {
        let profileId = UUID()
        let result = HospitalStarter.seed(profileId: profileId, language: .english)
        let hospitalRoom = result.scenes.first { $0.name == "Hospital Room" }
        XCTAssertNotNil(hospitalRoom)
        XCTAssertFalse(hospitalRoom!.placements.isEmpty, "Hospital Room must have pre-placed objects")
    }

    // MARK: - Spanish

    func test_spanishStarter_hasHospitalRoomScene() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        let sceneNames = result.scenes.map(\.name)
        XCTAssertTrue(sceneNames.contains("Habitación Hospital"))
    }

    func test_spanishStarter_includesCallNurseEquivalent() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        let labels = result.objects.map(\.label)
        XCTAssertTrue(labels.contains("Llamar enfermera"))
    }

    func test_spanishStarter_includesNeedBathroomEquivalent() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        let labels = result.objects.map(\.label)
        XCTAssertTrue(labels.contains("Necesito el baño"))
    }

    // MARK: - Object completeness

    func test_starter_allObjectsBelongToProfile() {
        let profileId = UUID()
        let result = HospitalStarter.seed(profileId: profileId, language: .english)
        XCTAssertTrue(result.objects.allSatisfy { $0.profileId == profileId })
    }

    func test_starter_allPlacementsReferenceValidObjects() {
        let profileId = UUID()
        let result = HospitalStarter.seed(profileId: profileId, language: .english)
        let objectIDs = Set(result.objects.map(\.id))
        for scene in result.scenes {
            for placement in scene.placements {
                XCTAssertTrue(
                    objectIDs.contains(placement.objectId),
                    "Placement \(placement.id) references unknown object \(placement.objectId)"
                )
            }
        }
    }
}
