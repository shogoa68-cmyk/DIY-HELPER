import XCTest
@testable import KabeBaseCore

final class AnchorAdvisorTests: XCTestCase {
    func testGypsumOnlyReturnsAnchor() {
        let result = FasteningAdvisor.advise(FasteningInput(attached: .board(thicknessMM: 12), target: .gypsumBoardOnly(.t12_5), load: .medium))
        guard case .anchor(let a) = result else { return XCTFail("アンカーになるはず") }
        XCTAssertEqual(a.primary, .screwInAnchor)
        XCTAssertEqual(a.board, .t12_5)
        XCTAssertEqual(result.restorationLevel, .puttyRequired)
    }

    func testLightLoadIsPinHole() {
        let a = AnchorAdvisor.recommend(board: .t9_5, load: .light)
        XCTAssertEqual(a.primary, .pinHook)
        XCTAssertEqual(a.restorationLevel, .pinHole)
    }

    func testHeavyLoadUsesToggle() {
        XCTAssertEqual(AnchorAdvisor.recommend(board: .t12_5, load: .heavy).primary, .toggleAnchor)
    }

    func testVeryHeavyIsNotRecommended() {
        let a = AnchorAdvisor.recommend(board: .t12_5, load: .veryHeavy)
        XCTAssertNil(a.primary)
        XCTAssertTrue(a.alternatives.isEmpty)
        XCTAssertFalse(a.notes.isEmpty)
    }

    func testScrewResultNeedsPutty() {
        let result = FasteningAdvisor.advise(FasteningInput(attached: .oneByFour, target: .twoByFour))
        XCTAssertEqual(result.restorationLevel, .puttyRequired)
        XCTAssertEqual(result.summaryLine, "スリムビス（細軸） 45mm／下穴 2mm")
    }

    func testCalculationRoundTripsThroughJSON() throws {
        let calc = FasteningAdvisor.calculate(FasteningInput(attached: .board(thicknessMM: 9), target: .studBehindGypsum(.t9_5), load: .heavy))
        let data = try JSONEncoder().encode(calc)
        let decoded = try JSONDecoder().decode(FasteningCalculation.self, from: data)
        XCTAssertEqual(decoded, calc)
    }
}
