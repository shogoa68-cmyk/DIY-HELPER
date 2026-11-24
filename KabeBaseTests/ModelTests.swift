import XCTest
import SwiftData
import KabeBaseCore
@testable import KabeBase

@MainActor
final class ModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try AppSchema.makeContainer(inMemory: true)
    }

    func testDeletingRoomDeletesWallsAndAnnotations() throws {
        let room = Room(name: "リビング")
        let wall = WallSurface(name: "北面")
        let pin = WallAnnotation(kind: .pin, x: 0.5, y: 0.5)
        context.insert(room)
        room.walls.append(wall)
        wall.annotations.append(pin)
        try context.save()

        context.delete(room)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WallSurface>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WallAnnotation>()), 0)
    }

    func testCalibrationIsStoredAndRestored() throws {
        let wall = WallSurface(name: "東面")
        wall.imagePixelWidth = 2000
        wall.imagePixelHeight = 1500
        wall.calibration = ScaleCalibration(
            pointA: NormalizedPoint(x: 0, y: 0.5),
            pointB: NormalizedPoint(x: 0.5, y: 0.5),
            realDistanceMM: 910,
            imagePixelWidth: 2000,
            imagePixelHeight: 1500
        )
        context.insert(wall)
        try context.save()

        let restored = try XCTUnwrap(wall.calibration)
        XCTAssertEqual(restored.imageWidthMM, 1820, accuracy: 1e-9)
    }

    func testCalcRecordRoundTrip() throws {
        let calc = FasteningAdvisor.calculate(FasteningInput(attached: .oneByFour, target: .twoByFour))
        let record = DiyCalcRecord.make(from: calc)
        context.insert(record)

        let pin = WallAnnotation(kind: .pin, x: 0.2, y: 0.3)
        pin.fastenerName = record.title
        pin.restoration = calc.result.restorationLevel
        pin.calcRecord = record
        context.insert(pin)
        try context.save()

        XCTAssertEqual(record.fasteningCalculation, calc)
        XCTAssertEqual(record.annotations.count, 1)
        XCTAssertEqual(pin.restoration, .puttyRequired)

        // 計算履歴を消しても、ピンは残る（nullify）
        context.delete(record)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WallAnnotation>()), 1)
        XCTAssertNil(pin.calcRecord)
    }
}
