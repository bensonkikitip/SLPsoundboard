import XCTest
@testable import SceneTalk

/// Tests for ObjectLibrary — per-profile CRUD over SceneObjects.
@MainActor
final class ObjectLibraryTests: XCTestCase {

    private var library: ObjectLibrary!
    private var profileId: UUID!

    override func setUp() {
        super.setUp()
        profileId = UUID()
        library = ObjectLibrary(profileId: profileId)
    }

    // MARK: - Initial state

    func test_emptyLibraryHasNoObjects() {
        XCTAssertTrue(library.objects.isEmpty)
    }

    // MARK: - Add

    func test_addObject_appearsInLibrary() {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        library.add(obj)
        XCTAssertEqual(library.objects.count, 1)
        XCTAssertEqual(library.objects.first?.label, "Apple")
    }

    func test_addMultipleObjects_allAppear() {
        let a = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        let b = SceneObject(profileId: profileId, label: "Call nurse", kind: .phraseIntent)
        library.add(a)
        library.add(b)
        XCTAssertEqual(library.objects.count, 2)
    }

    // MARK: - Update

    func test_updateObject_changesLabel() {
        var obj = SceneObject(profileId: profileId, label: "Old label", kind: .noun)
        library.add(obj)
        obj.label = "New label"
        library.update(obj)
        XCTAssertEqual(library.objects.first?.label, "New label")
    }

    func test_updateObject_notInLibrary_doesNothing() {
        let foreign = SceneObject(profileId: profileId, label: "Ghost", kind: .noun)
        library.update(foreign) // should not throw or crash
        XCTAssertTrue(library.objects.isEmpty)
    }

    // MARK: - Delete

    func test_deleteObject_removesFromLibrary() {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        library.add(obj)
        library.delete(obj)
        XCTAssertTrue(library.objects.isEmpty)
    }

    func test_deleteObject_notInLibrary_doesNothing() {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        library.add(obj)
        let foreign = SceneObject(profileId: profileId, label: "Ghost", kind: .noun)
        library.delete(foreign)
        XCTAssertEqual(library.objects.count, 1)
    }

    // MARK: - Lookup

    func test_objectByID_returnsCorrectObject() {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        library.add(obj)
        XCTAssertEqual(library.object(id: obj.id)?.label, "Apple")
    }

    func test_objectByID_unknownID_returnsNil() {
        XCTAssertNil(library.object(id: UUID()))
    }

    // MARK: - Filter by kind

    func test_filterByKind_nouns() {
        library.add(SceneObject(profileId: profileId, label: "Apple", kind: .noun))
        library.add(SceneObject(profileId: profileId, label: "Call nurse", kind: .phraseIntent))
        let nouns = library.objects(kind: .noun)
        XCTAssertEqual(nouns.count, 1)
        XCTAssertEqual(nouns.first?.label, "Apple")
    }

    func test_filterByKind_phraseIntents() {
        library.add(SceneObject(profileId: profileId, label: "Apple", kind: .noun))
        library.add(SceneObject(profileId: profileId, label: "Need bathroom", kind: .phraseIntent))
        XCTAssertEqual(library.objects(kind: .phraseIntent).count, 1)
    }
}
