import XCTest
@testable import KabeBaseCore

final class PilotHoleCalculatorTests: XCTestCase {
    func testSoftwood() {
        let r = PilotHoleCalculator.recommend(screwDiameterMM: 3.8, hardness: .softwood)
        XCTAssertEqual(r?.drillBitMM, 2.5)
        XCTAssertEqual(r?.idealDiameterMM ?? 0, 2.47, accuracy: 0.001)
        XCTAssertEqual(r?.acceptableRangeMM.lowerBound ?? 0, 2.28, accuracy: 0.001)
        XCTAssertEqual(r?.acceptableRangeMM.upperBound ?? 0, 2.66, accuracy: 0.001)
    }

    func testHardwood() {
        let r = PilotHoleCalculator.recommend(screwDiameterMM: 3.8, hardness: .hardwood)
        XCTAssertEqual(r?.drillBitMM, 3.0) // 3.8 × 0.75 = 2.85
    }

    func testTieChoosesSmallerBit() {
        XCTAssertEqual(PilotHoleCalculator.nearestBit(to: 2.25, in: [2.0, 2.5]), 2.0)
    }

    func testInvalidDiameter() {
        XCTAssertNil(PilotHoleCalculator.recommend(screwDiameterMM: 0, hardness: .softwood))
        XCTAssertNil(PilotHoleCalculator.recommend(screwDiameterMM: 3.8, hardness: .softwood, availableBitsMM: []))
    }
}
