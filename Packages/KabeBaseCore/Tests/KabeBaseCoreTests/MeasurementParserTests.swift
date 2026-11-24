import XCTest
@testable import KabeBaseCore

final class MeasurementParserTests: XCTestCase {
    func testParsesVariousFormats() {
        XCTAssertEqual(MeasurementParser.value(from: "2400"), 2400)
        XCTAssertEqual(MeasurementParser.value(from: "2,400"), 2400)
        XCTAssertEqual(MeasurementParser.value(from: "２４００"), 2400)
        XCTAssertEqual(MeasurementParser.value(from: " 2400mm "), 2400)
        XCTAssertEqual(MeasurementParser.value(from: "2400.5"), 2400.5)
        XCTAssertEqual(MeasurementParser.value(from: "２４００．５ｍｍ"), 2400.5)
    }

    func testRejectsInvalid() {
        XCTAssertNil(MeasurementParser.value(from: ""))
        XCTAssertNil(MeasurementParser.value(from: "abc"))
        XCTAssertNil(MeasurementParser.value(from: "0"))
        XCTAssertNil(MeasurementParser.value(from: "-5"))
    }

    func testValuesSkipsEmptyAndReportsInvalid() {
        let r = MeasurementParser.values(from: ["2400", "", "x", "2398"])
        XCTAssertEqual(r.values, [2400, 2398])
        XCTAssertEqual(r.invalidIndices, [2])
    }

    func testShortNames() {
        XCTAssertEqual(AttachedMaterial.board(thicknessMM: 12).shortName, "板 12mm")
        XCTAssertEqual(GypsumBoardThickness.t9_5.displayName, "9.5mm")
    }

    func testHasPurchasableItem() {
        XCTAssertTrue(FasteningAdvisor.advise(FasteningInput(attached: .oneByFour, target: .twoByFour)).hasPurchasableItem)
        XCTAssertFalse(FasteningAdvisor.advise(FasteningInput(attached: .oneByFour, target: .gypsumBoardOnly(.t12_5), load: .veryHeavy)).hasPurchasableItem)
    }

    func testLoadUpperKg() {
        XCTAssertEqual(LoadClass.medium.upperKg, 10)
        XCTAssertNil(LoadClass.veryHeavy.upperKg)
    }
}
