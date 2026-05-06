import XCTest
@testable import SceneTalk

/// Tests that the Hospital starter seed produces noun-only content for each language.
/// V2: Hospital scene contains only physical noun objects (Bed, TV, Toilet, etc.).
/// Action vocabulary lives in the Essentials bar, not the scene.
final class HospitalStarterTests: XCTestCase {

    // MARK: - English

    func test_englishStarter_hasHospitalRoomScene() {
        let profileId = UUID()
        let result = HospitalStarter.seed(profileId: profileId, language: .english)
        let sceneNames = result.scenes.map(\.name)
        XCTAssertTrue(sceneNames.contains("Hospital Room"), "Must include a Hospital Room scene")
    }

    func test_englishStarter_includesBed() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Bed"))
    }

    func test_englishStarter_includesTV() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("TV"))
    }

    func test_englishStarter_includesToilet() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Toilet"))
    }

    func test_englishStarter_includesCup() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Cup"))
    }

    func test_englishStarter_includesIVPole() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("IV pole"))
    }

    func test_englishStarter_includesWindow() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Window"))
    }

    func test_englishStarter_includesClock() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Clock"))
    }

    func test_englishStarter_includesNurseCallButton() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(result.objects.map(\.label).contains("Nurse call"))
    }

    // MARK: - Noun-only invariant

    func test_starter_allObjectsAreNouns() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        XCTAssertTrue(
            result.objects.allSatisfy { $0.kind == .noun },
            "Hospital scene should only contain noun objects"
        )
    }

    func test_starter_objectsHaveNoTtsOverride_soTapSpeaksLabel() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        for object in result.objects {
            XCTAssertEqual(
                object.ttsText, object.label,
                "Object '\(object.label)' should speak its own label, not an override"
            )
        }
    }

    func test_starter_hospitalSceneHasBackground() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        let scene = result.scenes.first { $0.name == "Hospital Room" }
        XCTAssertEqual(scene?.backgroundAssetName, "procedural:hospital")
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

    func test_spanishStarter_includesCama() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        XCTAssertTrue(result.objects.map(\.label).contains("Cama"))
    }

    func test_spanishStarter_includesInodoro() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        XCTAssertTrue(result.objects.map(\.label).contains("Inodoro"))
    }

    func test_spanishStarter_includesTelevision() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        XCTAssertTrue(result.objects.map(\.label).contains("Televisión"))
    }

    func test_spanishStarter_allObjectsAreNouns() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .spanish)
        XCTAssertTrue(result.objects.allSatisfy { $0.kind == .noun })
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

    func test_starter_allObjectsHaveArtworkKey() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        for object in result.objects {
            XCTAssertNotNil(
                object.imageAssetName,
                "Seeded object '\(object.label)' should have an artwork key in imageAssetName"
            )
        }
    }
}
