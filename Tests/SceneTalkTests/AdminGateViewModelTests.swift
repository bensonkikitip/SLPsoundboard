import XCTest
@testable import SceneTalk

/// Tests for the PIN-gate state machine that controls access to Admin mode.
@MainActor
final class AdminGateViewModelTests: XCTestCase {

    private var profile: Profile!

    override func setUp() {
        super.setUp()
        var p = Profile(name: "Test", language: .english, storageMode: .hospital)
        p.setPIN("1234")
        profile = p
    }

    // MARK: - Initial state

    func test_initialState_isIdle() {
        let vm = AdminGateViewModel(profile: profile)
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertEqual(vm.digits, "")
        XCTAssertFalse(vm.isUnlocked)
    }

    // MARK: - Digit entry

    func test_appendDigit_addsToDigits() {
        let vm = AdminGateViewModel(profile: profile)
        vm.append("1")
        XCTAssertEqual(vm.digits, "1")
    }

    func test_appendFourDigits_transitionsToVerifying() {
        let vm = AdminGateViewModel(profile: profile)
        "1234".forEach { vm.append(String($0)) }
        // After 4 digits the VM auto-verifies synchronously.
        XCTAssertEqual(vm.digits.count, 4)
    }

    func test_appendMoreThanFourDigits_isIgnored() {
        let vm = AdminGateViewModel(profile: profile)
        "12345".forEach { vm.append(String($0)) }
        XCTAssertEqual(vm.digits.count, 4)
    }

    func test_deleteLastDigit_removesLastCharacter() {
        let vm = AdminGateViewModel(profile: profile)
        vm.append("1")
        vm.append("2")
        vm.deleteLast()
        XCTAssertEqual(vm.digits, "1")
    }

    func test_deleteLastDigit_onEmptyDigits_doesNothing() {
        let vm = AdminGateViewModel(profile: profile)
        vm.deleteLast()
        XCTAssertEqual(vm.digits, "")
    }

    // MARK: - Verification outcomes

    func test_correctPIN_unlocksAdmin() {
        let vm = AdminGateViewModel(profile: profile)
        "1234".forEach { vm.append(String($0)) }
        XCTAssertTrue(vm.isUnlocked)
        XCTAssertEqual(vm.phase, .unlocked)
    }

    func test_wrongPIN_transitionsToFailed() {
        let vm = AdminGateViewModel(profile: profile)
        "9999".forEach { vm.append(String($0)) }
        XCTAssertFalse(vm.isUnlocked)
        XCTAssertEqual(vm.phase, .failed)
    }

    func test_afterFailure_resetClearsDigitsAndReturnsToIdle() {
        let vm = AdminGateViewModel(profile: profile)
        "9999".forEach { vm.append(String($0)) }
        XCTAssertEqual(vm.phase, .failed)
        vm.reset()
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertEqual(vm.digits, "")
        XCTAssertFalse(vm.isUnlocked)
    }

    // MARK: - Lock

    func test_lock_afterUnlock_returnsToIdle() {
        let vm = AdminGateViewModel(profile: profile)
        "1234".forEach { vm.append(String($0)) }
        XCTAssertTrue(vm.isUnlocked)
        vm.lock()
        XCTAssertFalse(vm.isUnlocked)
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertEqual(vm.digits, "")
    }
}
