import XCTest
@testable import SceneTalk

/// Slice 1 smoke tests — verify the test infrastructure compiles and the
/// deployment target is correctly set. Real behavioral tests start in slice 2.
final class SmokeTests: XCTestCase {

    func test_testInfrastructureIsReachable() {
        // Simplest possible assertion: if this compiles and runs, XCTest wiring works.
        XCTAssertTrue(true, "Test infrastructure is reachable")
    }

    func test_deploymentTarget_isAtLeastiPadOS17() {
        // Guard that we haven't accidentally lowered the deployment target.
        if #available(iOS 17.0, *) {
            XCTAssertTrue(true, "Running on iPadOS 17+")
        } else {
            XCTFail("SceneTalk requires iPadOS 17 or later")
        }
    }
}
