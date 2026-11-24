import XCTest
@testable import KabeBaseCore

final class WallMapMathTests: XCTestCase {
    func testStudGridFromZero() {
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 1820, pitchMM: 455, offsetMM: 0), [0, 455, 910, 1365, 1820])
    }

    func testStudGridWithOffset() {
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 1820, pitchMM: 455, offsetMM: 100), [100, 555, 1010, 1465])
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 1820, pitchMM: 455, offsetMM: 555), [100, 555, 1010, 1465])
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 1820, pitchMM: 455, offsetMM: -100), [355, 810, 1265, 1720])
    }

    func testStudGridInvalid() {
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 1820, pitchMM: 0, offsetMM: 0), [])
        XCTAssertEqual(StudGrid.linePositionsMM(spanMM: 0, pitchMM: 303, offsetMM: 0), [])
    }

    func testCalibration() throws {
        // 横2000pxの写真で、左端から真ん中まで（1000px）が910mm
        let c = try XCTUnwrap(ScaleCalibration(
            pointA: NormalizedPoint(x: 0, y: 0.5),
            pointB: NormalizedPoint(x: 0.5, y: 0.5),
            realDistanceMM: 910,
            imagePixelWidth: 2000,
            imagePixelHeight: 1500
        ))
        XCTAssertEqual(c.mmPerPixel, 0.91, accuracy: 1e-9)
        XCTAssertEqual(c.imageWidthMM, 1820, accuracy: 1e-9)
        XCTAssertEqual(c.imageHeightMM, 1365, accuracy: 1e-9)
        XCTAssertEqual(c.distanceMM(from: NormalizedPoint(x: 0, y: 0), to: NormalizedPoint(x: 0.25, y: 0)), 455, accuracy: 1e-9)

        let lines = StudGrid.normalizedLinePositions(calibration: c, pitchMM: 455, offsetMM: 0)
        XCTAssertEqual(lines.count, 5)
        XCTAssertEqual(lines[1], 0.25, accuracy: 1e-9)
    }

    func testCalibrationRejectsInvalidInput() {
        let p = NormalizedPoint(x: 0.3, y: 0.3)
        XCTAssertNil(ScaleCalibration(pointA: p, pointB: p, realDistanceMM: 100, imagePixelWidth: 1000, imagePixelHeight: 1000))
        XCTAssertNil(ScaleCalibration(pointA: p, pointB: NormalizedPoint(x: 0.6, y: 0.3), realDistanceMM: 0, imagePixelWidth: 1000, imagePixelHeight: 1000))
    }

    func testProPlanPolicy() {
        XCTAssertTrue(ProPlanPolicy.canAddWall(currentWallCount: 1, isPro: false))
        XCTAssertFalse(ProPlanPolicy.canAddWall(currentWallCount: 2, isPro: false))
        XCTAssertTrue(ProPlanPolicy.canAddWall(currentWallCount: 50, isPro: true))
        XCTAssertFalse(ProPlanPolicy.canAddPin(currentPinCount: 10, isPro: false))
        XCTAssertEqual(ProPlanPolicy.remainingPins(currentPinCount: 3, isPro: false), 7)
        XCTAssertNil(ProPlanPolicy.remainingWalls(currentWallCount: 3, isPro: true))
    }
}
