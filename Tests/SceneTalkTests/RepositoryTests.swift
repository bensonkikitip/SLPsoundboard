import XCTest
@testable import SceneTalk

/// Integration tests for EncryptedLocalRepository (hospital mode).
/// Uses a temporary directory so tests are fully isolated.
@MainActor
final class RepositoryTests: XCTestCase {

    private var tempDir: URL!
    private var profileId: UUID!
    private var repo: EncryptedLocalRepository!
    private var profile: Profile!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SceneTalkRepoTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        profileId = UUID()
        var p = Profile(id: profileId, name: "Test Patient", language: .english, storageMode: .hospital)
        p.setPIN("1234")
        profile = p

        repo = EncryptedLocalRepository(baseDirectory: tempDir, pin: "1234", profileId: profileId)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - Profile persistence

    func test_saveAndLoad_profile_roundtrips() async throws {
        try await repo.save(profile: profile)
        let loaded = try await repo.loadProfile(id: profileId)
        XCTAssertEqual(loaded?.id, profile.id)
        XCTAssertEqual(loaded?.name, profile.name)
        XCTAssertEqual(loaded?.language, profile.language)
    }

    func test_loadProfile_returnsNil_whenNotFound() async throws {
        let loaded = try await repo.loadProfile(id: UUID())
        XCTAssertNil(loaded)
    }

    // MARK: - Object persistence

    func test_saveAndLoad_objects_roundtrips() async throws {
        let obj1 = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        let obj2 = SceneObject(profileId: profileId, label: "Call nurse", kind: .phraseIntent,
                               ttsOverride: "Please call the nurse")
        try await repo.save(objects: [obj1, obj2], profileId: profileId)
        let loaded = try await repo.loadObjects(profileId: profileId)
        XCTAssertEqual(loaded.count, 2)
        let labels = Set(loaded.map(\.label))
        XCTAssertTrue(labels.contains("Apple"))
        XCTAssertTrue(labels.contains("Call nurse"))
    }

    func test_saveObjects_overwritesPrevious() async throws {
        let obj1 = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        try await repo.save(objects: [obj1], profileId: profileId)
        let obj2 = SceneObject(profileId: profileId, label: "Banana", kind: .noun)
        try await repo.save(objects: [obj2], profileId: profileId)
        let loaded = try await repo.loadObjects(profileId: profileId)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.label, "Banana")
    }

    func test_loadObjects_returnsEmpty_whenNoFile() async throws {
        let loaded = try await repo.loadObjects(profileId: UUID())
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Scene persistence

    func test_saveAndLoad_scenes_roundtrips() async throws {
        let obj = SceneObject(profileId: profileId, label: "Bed", kind: .noun)
        let placement = Placement(objectId: obj.id, sceneId: UUID(), x: 0.5, y: 0.5)
        let scene = SceneTalkScene(
            profileId: profileId,
            name: "Hospital Room",
            placements: [placement]
        )
        try await repo.save(scenes: [scene], profileId: profileId)
        let loaded = try await repo.loadScenes(profileId: profileId)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Hospital Room")
        XCTAssertEqual(loaded.first?.placements.count, 1)
    }

    // MARK: - Wrong PIN = no access

    func test_wrongPIN_throwsOrReturnsNil() async throws {
        try await repo.save(profile: profile)
        let wrongRepo = EncryptedLocalRepository(baseDirectory: tempDir, pin: "9999", profileId: profileId)
        do {
            let result = try await wrongRepo.loadProfile(id: profileId)
            // Some implementations return nil for decryption failure; both nil and throw are acceptable
            XCTAssertNil(result, "Wrong PIN should not decrypt the data")
        } catch {
            // Also acceptable — wrong key causes a decryption error
        }
    }

    // MARK: - Data survives app restart simulation

    func test_dataPersists_acrossNewRepositoryInstances() async throws {
        let obj = SceneObject(profileId: profileId, label: "Water", kind: .phraseIntent)
        try await repo.save(objects: [obj], profileId: profileId)

        // Simulate a fresh app launch: new repository instance, same dir + PIN
        let freshRepo = EncryptedLocalRepository(baseDirectory: tempDir, pin: "1234", profileId: profileId)
        let loaded = try await freshRepo.loadObjects(profileId: profileId)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.label, "Water")
    }
}
