import XCTest
@testable import KabeBaseCore

final class ScrewCalculatorTests: XCTestCase {
    private func screw(_ input: FasteningInput, file: StaticString = #filePath, line: UInt = #line) throws -> ScrewRecommendation {
        guard case .screw(let s) = FasteningAdvisor.advise(input) else {
            XCTFail("ビスの結果になるはず", file: file, line: line)
            throw XCTSkip()
        }
        return s
    }

    func testLengthRangeFollowsSpecFormula() {
        // 1×4(19) → 2×4(38)：最小 19+20=39、最大 19+38-2=55
        let r = ScrewCalculator.lengthRange(attachedThicknessMM: 19, holdingThicknessMM: 38)
        XCTAssertEqual(r.minimumMM, 39, accuracy: 0.001)
        XCTAssertEqual(r.maximumMM, 55, accuracy: 0.001)
        XCTAssertTrue(r.isSatisfiable)
    }

    func testOneByFourOntoTwoByFour() throws {
        let s = try screw(FasteningInput(attached: .oneByFour, target: .twoByFour))
        XCTAssertEqual(s.status, .ok)
        XCTAssertEqual(s.lengthMM, 45)
        XCTAssertEqual(s.screwType, .slim, "19mm以下はスリムビス")
        XCTAssertEqual(s.alternativeLengthsMM, [41, 51])
        XCTAssertEqual(s.pilotHole?.drillBitMM, 2.0) // 3.3 × 0.65 = 2.145 → 2.0
    }

    func testTwoByFourOntoTwoByFour() throws {
        let s = try screw(FasteningInput(attached: .twoByFour, target: .twoByFour))
        XCTAssertEqual(s.status, .ok)
        XCTAssertEqual(s.lengthMM, 65)
        XCTAssertEqual(s.screwType, .coarseThread)
        XCTAssertEqual(s.diameterMM, 3.8)
        XCTAssertEqual(s.pilotHole?.drillBitMM, 2.5) // 3.8 × 0.65 = 2.47 → 2.5
    }

    func testTwoByFourEdgeScrewingUsesSlim() throws {
        let s = try screw(FasteningInput(attached: .twoByFour, target: .twoByFour, isEdgeScrewing: true))
        XCTAssertEqual(s.screwType, .slim)
        XCTAssertEqual(s.lengthMM, 65)
    }

    func testPlywood12OntoTwoByFour() throws {
        let s = try screw(FasteningInput(attached: .board(thicknessMM: 12), target: .twoByFour))
        XCTAssertEqual(s.lengthMM, 38)
        XCTAssertEqual(s.screwType, .slim)
    }

    func testBoard24UsesCoarseThread() throws {
        let s = try screw(FasteningInput(attached: .board(thicknessMM: 24), target: .twoByFour))
        XCTAssertEqual(s.screwType, .coarseThread)
        // 最小44・最大60・理想50.6 → 51
        XCTAssertEqual(s.lengthMM, 51)
    }

    func testHeavyLoadPrefersLongerScrew() throws {
        let light = try screw(FasteningInput(attached: .oneByFour, target: .twoByFour, load: .light))
        let heavy = try screw(FasteningInput(attached: .oneByFour, target: .twoByFour, load: .heavy))
        XCTAssertEqual(light.lengthMM, 45)
        XCTAssertEqual(heavy.lengthMM, 51)
    }

    func testVeryHeavyNeverExceedsMaximum() throws {
        let s = try screw(FasteningInput(attached: .twoByFour, target: .twoByFour, load: .veryHeavy))
        XCTAssertEqual(s.lengthMM, 65) // 75 は最大74を超えるので不可
        XCTAssertLessThanOrEqual(Double(s.lengthMM!), s.range.maximumMM)
    }

    func testThinTargetGivesInsufficientEmbed() throws {
        // 1×4 → 1×4：最小39 > 最大36 → 20mm効かせられない
        let s = try screw(FasteningInput(attached: .oneByFour, target: .oneByFour))
        XCTAssertEqual(s.status, .insufficientEmbed)
        XCTAssertEqual(s.lengthMM, 32)
        XCTAssertEqual(s.embedDepthMM ?? 0, 13, accuracy: 0.001)
        XCTAssertFalse(s.range.isSatisfiable)
    }

    func testNoCandidate() {
        let input = FasteningInput(attached: .oneByFour, target: .twoByFour)
        let s = ScrewCalculator.recommend(input, availableLengthsMM: [90])
        XCTAssertEqual(s.status, .noCandidate)
        XCTAssertNil(s.lengthMM)
        XCTAssertNil(s.pilotHole)
    }

    func testMetalBracketUsesCoarseThread() throws {
        let s = try screw(FasteningInput(attached: .metalBracket(thicknessMM: 2), target: .twoByFour))
        XCTAssertEqual(s.screwType, .coarseThread, "金具は木割れしないのでスリム判定しない")
        XCTAssertEqual(s.lengthMM, 32)
    }

    func testStudBehindGypsumAddsBoardThickness() throws {
        let s = try screw(FasteningInput(attached: .twoByFour, target: .studBehindGypsum(.t12_5)))
        XCTAssertEqual(s.range.minimumMM, 70.5, accuracy: 0.001) // 38 + 12.5 + 20
        XCTAssertEqual(s.lengthMM, 75)
        XCTAssertEqual(s.status, .ok)
    }

    func testOneByFourOntoStudBehind9_5() throws {
        let s = try screw(FasteningInput(attached: .oneByFour, target: .studBehindGypsum(.t9_5)))
        XCTAssertEqual(s.lengthMM, 65)
    }

    func testEveryPresetCombinationProducesSafeLength() {
        for attached in AttachedMaterial.presets {
            for target in TargetMaterial.presets {
                for load in LoadClass.allCases {
                    let input = FasteningInput(attached: attached, target: target, load: load)
                    guard case .screw(let s) = FasteningAdvisor.advise(input), let length = s.lengthMM else { continue }
                    XCTAssertLessThanOrEqual(Double(length), s.range.maximumMM, "\(attached) → \(target) が突き抜ける")
                    if s.status == .ok {
                        XCTAssertGreaterThanOrEqual(Double(length), s.range.minimumMM)
                    }
                }
            }
        }
    }
}
