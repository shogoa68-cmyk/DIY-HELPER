import XCTest
import KabeBaseCore
@testable import KabeBase

final class FasteningNavigatorModelTests: XCTestCase {
    func testDefaultIsOneByFourOntoTwoByFour() {
        let model = FasteningNavigatorModel()
        XCTAssertEqual(model.calculation.result.displayTitle, "スリムビス（細軸） 45mm")
    }

    func testMetalThicknessIsReflected() {
        let model = FasteningNavigatorModel()
        model.attachedPreset = .metalBracket(thicknessMM: 2)
        model.metalThicknessMM = 3.2
        XCTAssertEqual(model.attached, .metalBracket(thicknessMM: 3.2))
    }

    func testEdgeScrewingIgnoredForMetal() {
        let model = FasteningNavigatorModel()
        model.isEdgeScrewing = true
        model.attachedPreset = .metalBracket(thicknessMM: 2)
        XCTAssertFalse(model.input.isEdgeScrewing)
    }

    func testTargetMapping() {
        let model = FasteningNavigatorModel()
        model.targetKind = .stud
        model.gypsumThickness = .t9_5
        XCTAssertEqual(model.target, .studBehindGypsum(.t9_5))
        model.targetKind = .gypsumOnly
        XCTAssertEqual(model.target, .gypsumBoardOnly(.t9_5))
        XCTAssertFalse(model.showsScrewOptions)
    }
}

final class TensionPostModelTests: XCTestCase {
    func testEmptyUntilHeightEntered() {
        XCTAssertEqual(TensionPostModel().outcome, .empty)
    }

    func testSuccess() {
        let model = TensionPostModel()
        model.heightTexts = ["2400", "2398", "2401"]
        model.postCount = 2
        guard case .success(let calc) = model.outcome else { return XCTFail("計算できるはず") }
        XCTAssertEqual(calc.result.cutLengthMM, 2303)
        XCTAssertEqual(calc.result.postCount, 2)
    }

    func testInvalidTextIsReported() {
        let model = TensionPostModel()
        model.heightTexts = ["2400", "abc", ""]
        guard case .failure(let message) = model.outcome else { return XCTFail("エラーになるはず") }
        XCTAssertTrue(message.contains("中央"))
    }

    func testCustomAdjusterNeedsValue() {
        let model = TensionPostModel()
        model.heightTexts = ["2400", "", ""]
        model.adjusterChoice = .custom
        guard case .failure = model.outcome else { return XCTFail("差し引き値が必要") }
        model.customDeductionText = "60"
        guard case .success(let calc) = model.outcome else { return XCTFail("計算できるはず") }
        XCTAssertEqual(calc.result.cutLengthMM, 2340)
    }

    func testMeasurementLimit() {
        let model = TensionPostModel()
        for _ in 0..<10 { model.addMeasurement() }
        XCTAssertEqual(model.heightTexts.count, TensionPostModel.maxMeasurements)
        XCTAssertEqual(model.measurementLabel(for: 3), "4か所目")
    }
}
