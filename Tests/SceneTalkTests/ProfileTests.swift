import XCTest
@testable import SceneTalk

/// Behavioral tests for Profile creation, PIN hashing, and storage mode.
/// Tests verify public behavior through the Profile API only — no internal
/// implementation details exposed.
final class ProfileTests: XCTestCase {

    // MARK: - Creation

    func test_profile_hasRequiredFields() {
        let profile = Profile(
            name: "Alex",
            language: .english,
            storageMode: .home
        )
        XCTAssertFalse(profile.id.uuidString.isEmpty)
        XCTAssertEqual(profile.name, "Alex")
        XCTAssertEqual(profile.language, .english)
        XCTAssertEqual(profile.storageMode, .home)
        XCTAssertFalse(profile.hasPIN, "New profile should have no PIN set")
    }

    func test_profile_spanish_language() {
        let profile = Profile(name: "María", language: .spanish, storageMode: .hospital)
        XCTAssertEqual(profile.language, .spanish)
        XCTAssertEqual(profile.storageMode, .hospital)
    }

    // MARK: - PIN

    func test_setPIN_marksProfileAsPINProtected() {
        var profile = Profile(name: "Sam", language: .english, storageMode: .hospital)
        XCTAssertFalse(profile.hasPIN)
        profile.setPIN("1234")
        XCTAssertTrue(profile.hasPIN)
    }

    func test_verifyPIN_correctPIN_returnsTrue() {
        var profile = Profile(name: "Sam", language: .english, storageMode: .hospital)
        profile.setPIN("9876")
        XCTAssertTrue(profile.verifyPIN("9876"))
    }

    func test_verifyPIN_wrongPIN_returnsFalse() {
        var profile = Profile(name: "Sam", language: .english, storageMode: .hospital)
        profile.setPIN("9876")
        XCTAssertFalse(profile.verifyPIN("0000"))
    }

    func test_verifyPIN_withNoPINSet_alwaysReturnsFalse() {
        let profile = Profile(name: "Sam", language: .english, storageMode: .home)
        XCTAssertFalse(profile.verifyPIN("0000"))
    }

    func test_pinIsNotStoredAsPlaintext() {
        var profile = Profile(name: "Sam", language: .english, storageMode: .hospital)
        profile.setPIN("1234")
        // The raw "1234" string should not appear in the serialized PIN storage.
        // We verify by checking the pinHash (if exposed) is non-empty but ≠ "1234".
        XCTAssertNotNil(profile.pinHash)
        XCTAssertNotEqual(profile.pinHash, "1234")
    }

    // MARK: - StorageMode

    func test_storageMode_home() {
        let profile = Profile(name: "Alex", language: .english, storageMode: .home)
        XCTAssertEqual(profile.storageMode, .home)
    }

    func test_storageMode_hospital() {
        let profile = Profile(name: "Alex", language: .english, storageMode: .hospital)
        XCTAssertEqual(profile.storageMode, .hospital)
    }

    // MARK: - Equality & Identity

    func test_twoProfilesWithSameID_areEqual() {
        let id = UUID()
        let a = Profile(id: id, name: "A", language: .english, storageMode: .home)
        let b = Profile(id: id, name: "A", language: .english, storageMode: .home)
        XCTAssertEqual(a, b)
    }

    func test_twoProfilesWithDifferentIDs_areNotEqual() {
        let a = Profile(name: "A", language: .english, storageMode: .home)
        let b = Profile(name: "A", language: .english, storageMode: .home)
        XCTAssertNotEqual(a, b)
    }
}
