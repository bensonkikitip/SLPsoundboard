import XCTest
@testable import SceneTalk

/// End-to-end integration tests for every core user flow.
///
/// These tests drive the public APIs that the UI layer uses — ProfileStore,
/// SceneEditorViewModel, ObjectLibrary — and verify the complete journey from
/// "new device" through "returning user with multiple profiles". Each test is
/// a self-contained scenario that exercises the full data path including
/// encrypt→persist→reload→decrypt.
///
/// Layout of test suites:
///   1. First-launch / setup wizard flow
///   2. Return-launch PIN unlock flow
///   3. Wrong PIN / security boundary
///   4. Multi-profile: add, isolate, select
///   5. V1 single-manifest migration
///   6. Forgot PIN / profile reset
///   7. Admin scene management (add, edit, hotspot, delete)
///   8. Admin object library
///   9. Session lifecycle (add profile while another is loaded)
@MainActor
final class CoreUserFlowTests: XCTestCase {

    // MARK: - Fixtures

    private var tempDir: URL!
    private var defaults: UserDefaults!
    private var store: ProfileStore!

    private let pin1 = "1234"
    private let pin2 = "5678"

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreUserFlowTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: "CoreUserFlowTests-\(UUID().uuidString)")!
        store = ProfileStore(defaults: defaults, dataDirectory: tempDir)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        defaults.removeSuite(named: defaults.description)
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeProfile(name: String = "Alice") -> Profile {
        var p = Profile(
            name: name,
            language: .english,
            storageMode: .hospital
        )
        p.setPIN(pin1)
        return p
    }

    private func makeProfile2(name: String = "Bob") -> Profile {
        var p = Profile(
            name: name,
            language: .spanish,
            storageMode: .hospital
        )
        p.setPIN(pin2)
        return p
    }

    private func makeScene(profileId: UUID, name: String = "Kitchen") -> SceneTalkScene {
        SceneTalkScene(profileId: profileId, name: name)
    }

    private func makeObject(profileId: UUID, label: String = "Apple") -> SceneObject {
        SceneObject(profileId: profileId, label: label, kind: .noun)
    }

    private func makeHotspot(sceneId: UUID) -> SceneHotspot {
        SceneHotspot(
            id: UUID(),
            sceneId: sceneId,
            label: "Stove",
            x: 0.1, y: 0.2,
            width: 0.3, height: 0.15
        )
    }

    /// Create a fresh ProfileStore backed by the same on-disk state.
    /// Simulates an app relaunch.
    private func relaunchStore() -> ProfileStore {
        ProfileStore(defaults: defaults, dataDirectory: tempDir)
    }

    // =========================================================================
    // MARK: - 1. First-launch / setup wizard
    // =========================================================================

    /// Scenario: brand-new device, no profiles.
    /// Wizard completes → profile is persisted → store reflects one profile.
    func test_firstLaunch_noProfiles_storeIsEmpty() {
        XCTAssertFalse(store.hasProfile, "Fresh store must report no profiles")
        XCTAssertTrue(store.manifests.isEmpty)
        XCTAssertNil(store.profile)
    }

    /// Scenario: wizard completes with name "Alice", PIN 1234.
    /// Store must have exactly one manifest with the correct name.
    func test_firstLaunch_wizardCompletes_profileIsPersisted() async throws {
        let profile = makeProfile(name: "Alice")
        let scene = makeScene(profileId: profile.id)
        let object = makeObject(profileId: profile.id)

        try await store.save(profile: profile, pin: pin1, objects: [object], scenes: [scene])

        XCTAssertTrue(store.hasProfile)
        XCTAssertEqual(store.manifests.count, 1)
        XCTAssertEqual(store.manifests.first?.name, "Alice")
        XCTAssertEqual(store.profile?.id, profile.id)
        XCTAssertEqual(store.objects.count, 1)
        XCTAssertEqual(store.scenes.count, 1)
    }

    /// Scenario: after saving, a new store instance (simulating app relaunch)
    /// must find the manifest without re-entering a PIN.
    func test_firstLaunch_profilePersistsAcrossRelaunch() async throws {
        let profile = makeProfile(name: "Alice")
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])

        let store2 = relaunchStore()

        XCTAssertTrue(store2.hasProfile)
        XCTAssertEqual(store2.manifests.first?.name, "Alice")
        XCTAssertNil(store2.profile, "Profile content is locked until PIN unlock")
    }

    // =========================================================================
    // MARK: - 2. Return-launch: correct PIN unlocks profile
    // =========================================================================

    /// Scenario: returning user enters correct PIN → profile and content load.
    func test_returnLaunch_correctPIN_unlocksProfile() async throws {
        let profile = makeProfile(name: "Alice")
        let scene = makeScene(profileId: profile.id, name: "Kitchen")
        let object = makeObject(profileId: profile.id, label: "Cup")
        try await store.save(profile: profile, pin: pin1, objects: [object], scenes: [scene])

        // Simulate relaunch — store starts locked
        let store2 = relaunchStore()
        let manifest = try XCTUnwrap(store2.manifests.first)

        let success = await store2.load(manifest: manifest, pin: pin1)

        XCTAssertTrue(success)
        XCTAssertEqual(store2.profile?.name, "Alice")
        XCTAssertEqual(store2.scenes.first?.name, "Kitchen")
        XCTAssertEqual(store2.objects.first?.label, "Cup")
    }

    // =========================================================================
    // MARK: - 3. Wrong PIN / security boundary
    // =========================================================================

    /// Scenario: user misremembers PIN → load fails, profile stays locked.
    func test_wrongPIN_returnsFailure_profileRemainsLocked() async throws {
        let profile = makeProfile()
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])

        let store2 = relaunchStore()
        let manifest = try XCTUnwrap(store2.manifests.first)

        let success = await store2.load(manifest: manifest, pin: "0000")

        XCTAssertFalse(success)
        XCTAssertNil(store2.profile)
        XCTAssertTrue(store2.objects.isEmpty)
        XCTAssertTrue(store2.scenes.isEmpty)
    }

    /// Scenario: correct PIN after a wrong attempt succeeds.
    func test_wrongThenCorrectPIN_eventuallySucceeds() async throws {
        let profile = makeProfile()
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])

        let store2 = relaunchStore()
        let manifest = try XCTUnwrap(store2.manifests.first)

        let fail = await store2.load(manifest: manifest, pin: "9999")
        XCTAssertFalse(fail)

        let succeed = await store2.load(manifest: manifest, pin: pin1)
        XCTAssertTrue(succeed)
        XCTAssertNotNil(store2.profile)
    }

    // =========================================================================
    // MARK: - 4. Multi-profile: add, isolate, select
    // =========================================================================

    /// Scenario: admin adds a second profile. Both manifests must be present.
    func test_multiProfile_addSecond_bothManifestsPresent() async throws {
        let p1 = makeProfile(name: "Alice")
        let p2 = makeProfile2(name: "Bob")

        try await store.save(profile: p1, pin: pin1, objects: [], scenes: [])
        try await store.save(profile: p2, pin: pin2, objects: [], scenes: [])

        XCTAssertEqual(store.manifests.count, 2)
        let names = store.manifests.map(\.name)
        XCTAssertTrue(names.contains("Alice"))
        XCTAssertTrue(names.contains("Bob"))
    }

    /// Scenario: two profiles have different scenes → loading profile 2 shows
    /// only profile 2's scenes, not profile 1's.
    func test_multiProfile_dataIsolation_eachProfileHasOwnScenes() async throws {
        let p1 = makeProfile(name: "Alice")
        let p2 = makeProfile2(name: "Bob")

        let sceneA = makeScene(profileId: p1.id, name: "Alice's Kitchen")
        let sceneB = makeScene(profileId: p2.id, name: "Bob's Living Room")

        try await store.save(profile: p1, pin: pin1, objects: [], scenes: [sceneA])
        try await store.save(profile: p2, pin: pin2, objects: [], scenes: [sceneB])

        let store2 = relaunchStore()
        let manifest2 = try XCTUnwrap(store2.manifests.first(where: { $0.name == "Bob" }))

        let ok = await store2.load(manifest: manifest2, pin: pin2)
        XCTAssertTrue(ok)
        XCTAssertEqual(store2.scenes.count, 1)
        XCTAssertEqual(store2.scenes.first?.name, "Bob's Living Room")
    }

    /// Scenario: selecting the first profile from the picker loads its data.
    func test_multiProfile_selectingFirstProfile_loadsCorrectData() async throws {
        let p1 = makeProfile(name: "Alice")
        let p2 = makeProfile2(name: "Bob")

        let obj1 = makeObject(profileId: p1.id, label: "Alice's Object")
        try await store.save(profile: p1, pin: pin1, objects: [obj1], scenes: [])
        try await store.save(profile: p2, pin: pin2, objects: [], scenes: [])

        let store2 = relaunchStore()
        let manifest1 = try XCTUnwrap(store2.manifests.first(where: { $0.name == "Alice" }))

        let ok = await store2.load(manifest: manifest1, pin: pin1)
        XCTAssertTrue(ok)
        XCTAssertEqual(store2.objects.first?.label, "Alice's Object")
    }

    // =========================================================================
    // MARK: - 5. V1 single-manifest migration
    // =========================================================================

    /// Scenario: device was running V1 which stored a single ProfileManifest
    /// under the legacy key. Upgrading creates a new store which must migrate
    /// the manifest to the V2 array format without data loss.
    func test_v1Migration_singleManifest_migratedToArray() throws {
        // Write a V1-style single manifest directly to defaults
        let legacyManifest = ProfileManifest(
            id: UUID(),
            name: "Legacy User",
            storageMode: .hospital,
            pinHash: Profile.hashPIN("9999")
        )
        let data = try JSONEncoder().encode(legacyManifest)
        defaults.set(data, forKey: "SceneTalk.ProfileManifest")  // V1 key

        // Create new store — migration happens in init
        let migratedStore = ProfileStore(defaults: defaults, dataDirectory: tempDir)

        XCTAssertEqual(migratedStore.manifests.count, 1)
        XCTAssertEqual(migratedStore.manifests.first?.name, "Legacy User")
        XCTAssertNil(defaults.data(forKey: "SceneTalk.ProfileManifest"), "V1 key should be removed after migration")
    }

    // =========================================================================
    // MARK: - 6. Forgot PIN / profile reset
    // =========================================================================

    /// Scenario: user forgets PIN and resets their profile. Profile is removed
    /// from the manifest list and its directory is wiped.
    func test_forgotPIN_deleteProfile_removesManifestAndData() async throws {
        let profile = makeProfile(name: "Alice")
        let scene = makeScene(profileId: profile.id)
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [scene])
        let manifest = try XCTUnwrap(store.manifests.first)

        store.deleteProfile(manifest)

        XCTAssertFalse(store.hasProfile)
        XCTAssertTrue(store.manifests.isEmpty)
        XCTAssertNil(store.profile)

        // On-disk data must be gone
        let profileDir = tempDir.appendingPathComponent(profile.id.uuidString)
        XCTAssertFalse(FileManager.default.fileExists(atPath: profileDir.path))
    }

    /// Scenario: two profiles, reset profile 1. Profile 2 remains untouched.
    func test_forgotPIN_deleteOneProfile_otherProfileUntouched() async throws {
        let p1 = makeProfile(name: "Alice")
        let p2 = makeProfile2(name: "Bob")
        try await store.save(profile: p1, pin: pin1, objects: [], scenes: [])
        try await store.save(profile: p2, pin: pin2, objects: [], scenes: [])

        let manifest1 = try XCTUnwrap(store.manifests.first(where: { $0.name == "Alice" }))
        store.deleteProfile(manifest1)

        XCTAssertEqual(store.manifests.count, 1)
        XCTAssertEqual(store.manifests.first?.name, "Bob")
    }

    /// Scenario: deleting active profile clears the in-memory session.
    func test_deleteActiveProfile_clearsSession() async throws {
        let profile = makeProfile()
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])
        let manifest = try XCTUnwrap(store.manifests.first)

        // Load the profile into memory
        _ = await store.load(manifest: manifest, pin: pin1)
        XCTAssertNotNil(store.profile, "precondition: profile should be loaded")

        store.deleteProfile(manifest)

        XCTAssertNil(store.profile)
        XCTAssertTrue(store.objects.isEmpty)
        XCTAssertTrue(store.scenes.isEmpty)
    }

    // =========================================================================
    // MARK: - 7. Admin scene management
    // =========================================================================

    /// Scenario: admin adds a new scene via SceneEditorViewModel and saves it.
    /// After relaunch, the new scene is present.
    func test_admin_addScene_persistsAcrossRelaunch() async throws {
        let profile = makeProfile()
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        // Admin creates a new scene
        var scenes = store.scenes
        let newScene = SceneTalkScene(profileId: profile.id, name: "Hospital Room")
        scenes.append(newScene)
        try await store.saveScenes(scenes, pin: pin1)

        // Relaunch and reload
        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        XCTAssertEqual(store2.scenes.count, 1)
        XCTAssertEqual(store2.scenes.first?.name, "Hospital Room")
    }

    /// Scenario: admin edits a scene name and saves.
    func test_admin_editScene_updatedNamePersists() async throws {
        let profile = makeProfile()
        var scene = makeScene(profileId: profile.id, name: "Old Name")
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [scene])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        scene.name = "New Name"
        try await store.saveScenes([scene], pin: pin1)

        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        XCTAssertEqual(store2.scenes.first?.name, "New Name")
    }

    /// Scenario: admin adds a placement to a scene via SceneEditorViewModel,
    /// saves through store — placement survives relaunch.
    func test_admin_addPlacement_persistsAcrossRelaunch() async throws {
        let profile = makeProfile()
        let scene = makeScene(profileId: profile.id)
        let object = makeObject(profileId: profile.id, label: "Stove")
        try await store.save(profile: profile, pin: pin1, objects: [object], scenes: [scene])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        // Admin opens scene editor and adds a placement
        let vm = SceneEditorViewModel(scene: scene, availableObjects: [object])
        vm.addPlacement(for: object, at: CGPoint(x: 0.5, y: 0.5))
        let updatedScene = vm.buildScene()
        try await store.saveScenes([updatedScene], pin: pin1)

        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        XCTAssertEqual(store2.scenes.first?.placements.count, 1)
        XCTAssertEqual(store2.scenes.first?.placements.first?.objectId, object.id)
    }

    /// Scenario: admin adds a hotspot region, saves — hotspot survives relaunch.
    func test_admin_addHotspot_persistsAcrossRelaunch() async throws {
        let profile = makeProfile()
        let scene = makeScene(profileId: profile.id)
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [scene])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        // Admin adds a hotspot via SceneEditorViewModel
        let vm = SceneEditorViewModel(scene: scene, availableObjects: [])
        let hotspot = SceneHotspot(
            id: UUID(),
            sceneId: scene.id,
            label: "Refrigerator",
            x: 0.6, y: 0.1,
            width: 0.2, height: 0.4
        )
        vm.addHotspot(hotspot)
        let updatedScene = vm.buildScene()
        try await store.saveScenes([updatedScene], pin: pin1)

        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        let loaded = try XCTUnwrap(store2.scenes.first)
        XCTAssertEqual(loaded.hotspots.count, 1)
        let hs = try XCTUnwrap(loaded.hotspots.first)
        XCTAssertEqual(hs.label, "Refrigerator")
        XCTAssertEqual(hs.x, 0.6, accuracy: 0.001)
        XCTAssertEqual(hs.width, 0.2, accuracy: 0.001)
    }

    /// Scenario: admin deletes a scene. After save it is gone on relaunch.
    func test_admin_deleteScene_sceneMissingAfterRelaunch() async throws {
        let profile = makeProfile()
        let scene1 = makeScene(profileId: profile.id, name: "Kitchen")
        let scene2 = makeScene(profileId: profile.id, name: "Living Room")
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [scene1, scene2])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        // Admin deletes scene1
        let remaining = store.scenes.filter { $0.id != scene1.id }
        try await store.saveScenes(remaining, pin: pin1)

        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        XCTAssertEqual(store2.scenes.count, 1)
        XCTAssertEqual(store2.scenes.first?.name, "Living Room")
    }

    // =========================================================================
    // MARK: - 8. Admin object library
    // =========================================================================

    /// Scenario: admin adds an object to the library and saves.
    /// Object is present after relaunch.
    func test_admin_addObject_persistsAcrossRelaunch() async throws {
        let profile = makeProfile()
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        let newObj = makeObject(profileId: profile.id, label: "Wheelchair")
        let lib = ObjectLibrary(profileId: profile.id, objects: store.objects)
        lib.add(newObj)
        try await store.saveObjects(lib.objects, pin: pin1)

        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)

        XCTAssertEqual(store2.objects.count, 1)
        XCTAssertEqual(store2.objects.first?.label, "Wheelchair")
    }

    /// Scenario: admin saves a cutout image for an object. Relative path is
    /// returned and the file exists on disk.
    func test_admin_saveCutout_fileExistsAndPathCorrect() throws {
        let profile = makeProfile()
        let objectId = UUID()
        let pngData = makeTinyPNG()

        let path = try store.saveCutout(pngData, profileId: profile.id, objectId: objectId)

        XCTAssertEqual(path, "\(profile.id.uuidString)/cutouts/\(objectId.uuidString).png")
        XCTAssertNotNil(store.assetURL(forRelativePath: path))
    }

    // =========================================================================
    // MARK: - 9. Session lifecycle
    // =========================================================================

    /// Scenario: user is in a session (profile loaded) and an admin adds a second
    /// profile via the wizard sheet. Both manifests persist; active session unchanged.
    func test_addProfileWhileSessionActive_bothManifestsPresent_sessionUnchanged() async throws {
        // Start a session as Alice
        let p1 = makeProfile(name: "Alice")
        let obj1 = makeObject(profileId: p1.id, label: "Alice's Cup")
        try await store.save(profile: p1, pin: pin1, objects: [obj1], scenes: [])
        let m1 = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: m1, pin: pin1)
        XCTAssertEqual(store.profile?.name, "Alice", "precondition")

        // Wizard adds a second profile (Bob) while Alice is loaded
        let p2 = makeProfile2(name: "Bob")
        try await store.save(profile: p2, pin: pin2, objects: [], scenes: [])

        // Two manifests should now exist
        XCTAssertEqual(store.manifests.count, 2)
        // Active session is still Alice's
        XCTAssertEqual(store.profile?.name, "Alice")
        XCTAssertEqual(store.objects.first?.label, "Alice's Cup")
    }

    /// Scenario: scenes updated in memory (optimistic UI) but not yet persisted —
    /// in-memory state reflects the change; persistent state is unchanged until save.
    func test_updateScenesInMemory_doesNotWriteToDisk() async throws {
        let profile = makeProfile()
        let scene = makeScene(profileId: profile.id, name: "Original")
        try await store.save(profile: profile, pin: pin1, objects: [], scenes: [scene])
        let manifest = try XCTUnwrap(store.manifests.first)
        _ = await store.load(manifest: manifest, pin: pin1)

        var updated = scene
        updated.name = "Modified In Memory"
        store.updateScenesInMemory([updated])

        // In-memory is updated
        XCTAssertEqual(store.scenes.first?.name, "Modified In Memory")

        // A fresh store from the same storage should still see "Original"
        let store2 = relaunchStore()
        let m2 = try XCTUnwrap(store2.manifests.first)
        _ = await store2.load(manifest: m2, pin: pin1)
        XCTAssertEqual(store2.scenes.first?.name, "Original", "Disk should be unchanged until saveScenes is called")
    }

    // =========================================================================
    // MARK: - Helpers
    // =========================================================================

    /// Smallest valid 1×1 transparent PNG — 67 bytes.
    private func makeTinyPNG() -> Data {
        Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x06, 0x00, 0x00, 0x00,
            0x1F, 0x15, 0xC4, 0x89,
            0x00, 0x00, 0x00, 0x0A,
            0x49, 0x44, 0x41, 0x54,
            0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x01,
            0x0D, 0x0A, 0x2D, 0xB4,
            0x00, 0x00, 0x00, 0x00,
            0x49, 0x45, 0x4E, 0x44,
            0xAE, 0x42, 0x60, 0x82
        ])
    }
}
