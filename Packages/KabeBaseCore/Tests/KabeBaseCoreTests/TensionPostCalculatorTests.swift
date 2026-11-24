import XCTest
@testable import KabeBaseCore

final class TensionPostCalculatorTests: XCTestCase {
    func testLabrico() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400, 2400, 2400], adjuster: .labrico2x4, postCount: 2))
        XCTAssertEqual(r.cutLengthMM, 2305)
        XCTAssertEqual(r.recommendedStock?.name, "8F")
        XCTAssertTrue(r.warnings.isEmpty)
        XCTAssertTrue(r.cutRequestMemo.contains("2305mm × 2本"))
        XCTAssertEqual(r.displayTitle, "2×4カット 2305mm × 2本")
    }

    func testDiawall() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400, 2401, 2402], adjuster: .diawall2x4))
        XCTAssertEqual(r.cutLengthMM, 2355)
    }

    func testUsesLowestMeasurementAndWarnsAboutSpread() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400, 2396, 2403], adjuster: .labrico2x4))
        XCTAssertEqual(r.baseHeightMM, 2396)
        XCTAssertEqual(r.cutLengthMM, 2301)
        XCTAssertEqual(r.heightSpreadMM, 7, accuracy: 0.001)
        XCTAssertTrue(r.warnings.contains { $0.contains("7mm") })
    }

    func testRemindsToMeasureMultiplePlaces() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400], adjuster: .labrico2x4))
        XCTAssertTrue(r.warnings.contains { $0.contains("3か所") })
    }

    func testRoundsDown() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400.7, 2400.7, 2400.7], adjuster: .labrico2x4))
        XCTAssertEqual(r.cutLengthMM, 2305)
    }

    func testCustomAdjuster() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2500, 2500, 2500], adjuster: .custom(deductionMM: 60)))
        XCTAssertEqual(r.cutLengthMM, 2440)
        XCTAssertEqual(r.recommendedStock?.name, "10F") // 8F(2438) では2mm足りない
    }

    func testTooLongForStock() throws {
        let r = try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [3800, 3800, 3800], adjuster: .labrico2x4))
        XCTAssertNil(r.recommendedStock)
        XCTAssertTrue(r.warnings.contains { $0.contains("12F") })
    }

    func testErrors() {
        XCTAssertThrowsError(try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [], adjuster: .labrico2x4))) {
            XCTAssertEqual($0 as? TensionPostError, .noMeasurements)
        }
        XCTAssertThrowsError(try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400, -1], adjuster: .labrico2x4))) {
            XCTAssertEqual($0 as? TensionPostError, .invalidMeasurement(-1))
        }
        XCTAssertThrowsError(try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [80], adjuster: .labrico2x4))) {
            XCTAssertEqual($0 as? TensionPostError, .heightTooLow(heightMM: 80, deductionMM: 95))
        }
        XCTAssertThrowsError(try TensionPostCalculator.calculate(TensionPostInput(measuredHeightsMM: [2400], adjuster: .labrico2x4, postCount: 0))) {
            XCTAssertEqual($0 as? TensionPostError, .invalidPostCount(0))
        }
    }
}
