import XCTest
@testable import SceneTalk

/// Tests for the first-launch setup WizardViewModel.
@MainActor
final class WizardViewModelTests: XCTestCase {

    private var vm: WizardViewModel!

    override func setUp() {
        super.setUp()
        vm = WizardViewModel()
    }

    // MARK: - Initial state

    func test_initialStep_isName() {
        XCTAssertEqual(vm.step, .name)
    }

    func test_initialName_isEmpty() {
        XCTAssertEqual(vm.patientName, "")
    }

    func test_initialLanguage_isEnglish() {
        XCTAssertEqual(vm.language, .english)
    }

    func test_initialMode_isHospital() {
        XCTAssertEqual(vm.storageMode, .hospital)
    }

    // MARK: - Name step

    func test_canProceedFromName_falseWhenEmpty() {
        vm.patientName = ""
        XCTAssertFalse(vm.canProceed)
    }

    func test_canProceedFromName_falseWhenWhitespaceOnly() {
        vm.patientName = "   "
        XCTAssertFalse(vm.canProceed)
    }

    func test_canProceedFromName_trueWhenNonEmpty() {
        vm.patientName = "Alex"
        XCTAssertTrue(vm.canProceed)
    }

    func test_next_fromName_goesToLanguage() {
        vm.patientName = "Alex"
        vm.next()
        XCTAssertEqual(vm.step, .language)
    }

    // MARK: - Language step

    func test_canProceedFromLanguage_alwaysTrue() {
        vm.patientName = "Alex"
        vm.next() // → .language
        XCTAssertTrue(vm.canProceed)
    }

    func test_next_fromLanguage_goesToMode() {
        vm.patientName = "Alex"
        vm.next() // → .language
        vm.next() // → .mode
        XCTAssertEqual(vm.step, .mode)
    }

    // MARK: - Mode step

    func test_canProceedFromMode_alwaysTrue() {
        vm.patientName = "Alex"
        vm.next(); vm.next() // → .mode
        XCTAssertTrue(vm.canProceed)
    }

    func test_next_fromMode_goesToPin() {
        vm.patientName = "Alex"
        vm.next(); vm.next(); vm.next() // → .pin
        XCTAssertEqual(vm.step, .pin)
    }

    // MARK: - PIN step

    func test_canProceedFromPin_falseWhenLessThan4Digits() {
        advanceToPin()
        vm.appendPINDigit("1")
        vm.appendPINDigit("2")
        vm.appendPINDigit("3")
        XCTAssertFalse(vm.canProceed)
    }

    func test_canProceedFromPin_falseWhenConfirmMismatch() {
        advanceToPin()
        "1234".forEach { vm.appendPINDigit(String($0)) }   // fill first entry
        "5678".forEach { vm.appendPINDigit(String($0)) }   // fill confirm
        XCTAssertFalse(vm.canProceed)
    }

    func test_canProceedFromPin_trueWhenBothMatch() {
        advanceToPin()
        "1234".forEach { vm.appendPINDigit(String($0)) }
        "1234".forEach { vm.appendPINDigit(String($0)) }
        XCTAssertTrue(vm.canProceed)
    }

    func test_next_fromPin_goesToDone() {
        advanceToPin()
        "1234".forEach { vm.appendPINDigit(String($0)) }
        "1234".forEach { vm.appendPINDigit(String($0)) }
        vm.next() // → .done
        XCTAssertEqual(vm.step, .done)
    }

    // MARK: - Back navigation

    func test_back_fromLanguage_goesToName() {
        vm.patientName = "Alex"
        vm.next() // → .language
        vm.back()
        XCTAssertEqual(vm.step, .name)
    }

    func test_back_fromName_isNoOp() {
        vm.back()
        XCTAssertEqual(vm.step, .name)
    }

    // MARK: - Build output

    func test_buildProfile_hasCorrectName() {
        let profile = buildCompletedProfile(name: "Sam", language: .english, mode: .hospital, pin: "9999")
        XCTAssertEqual(profile.name, "Sam")
    }

    func test_buildProfile_hasCorrectLanguage() {
        let profile = buildCompletedProfile(name: "Sam", language: .spanish, mode: .hospital, pin: "1234")
        XCTAssertEqual(profile.language, .spanish)
    }

    func test_buildProfile_hasCorrectMode() {
        let profile = buildCompletedProfile(name: "Sam", language: .english, mode: .home, pin: "1234")
        XCTAssertEqual(profile.storageMode, .home)
    }

    func test_buildProfile_hasPINSet() {
        let profile = buildCompletedProfile(name: "Sam", language: .english, mode: .hospital, pin: "4321")
        XCTAssertTrue(profile.verifyPIN("4321"))
        XCTAssertFalse(profile.verifyPIN("0000"))
    }

    func test_buildSeed_englishHasHospitalRoomScene() {
        let vm = WizardViewModel()
        vm.patientName = "Sam"
        vm.language = .english
        vm.storageMode = .hospital
        vm.next(); vm.next(); vm.next()
        "1234".forEach { vm.appendPINDigit(String($0)) }
        "1234".forEach { vm.appendPINDigit(String($0)) }
        vm.next() // done
        let seed = vm.buildSeed()
        let names = seed.scenes.map(\.name)
        XCTAssertTrue(names.contains("Hospital Room"))
    }

    func test_buildSeed_spanishHasHabitacionScene() {
        let vm = WizardViewModel()
        vm.patientName = "Sam"
        vm.language = .spanish
        vm.storageMode = .hospital
        vm.next(); vm.next(); vm.next()
        "1234".forEach { vm.appendPINDigit(String($0)) }
        "1234".forEach { vm.appendPINDigit(String($0)) }
        vm.next()
        let seed = vm.buildSeed()
        let names = seed.scenes.map(\.name)
        XCTAssertTrue(names.contains("Habitación Hospital"))
    }

    // MARK: - Helpers

    private func advanceToPin() {
        vm.patientName = "Alex"
        vm.next(); vm.next(); vm.next()
    }

    private func buildCompletedProfile(name: String, language: Language, mode: StorageMode, pin: String) -> Profile {
        let vm = WizardViewModel()
        vm.patientName = name
        vm.language = language
        vm.storageMode = mode
        vm.next(); vm.next(); vm.next()
        pin.forEach { vm.appendPINDigit(String($0)) }
        pin.forEach { vm.appendPINDigit(String($0)) }
        vm.next()
        return vm.buildProfile()
    }
}
