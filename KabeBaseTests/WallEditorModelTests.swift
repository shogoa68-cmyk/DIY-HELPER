import XCTest
import SwiftData
import KabeBaseCore
@testable import KabeBase

final class WallEditorModelTests: XCTestCase {
    private let transform = CanvasTransform(viewSize: CGSize(width: 400, height: 800), imageSize: CGSize(width: 2000, height: 1000))

    func testBrowseModeDoesNothing() {
        let model = WallEditorModel()
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 0.5, y: 0.5)), .none)
    }

    func testTapOutsidePhotoIsIgnored() {
        let model = WallEditorModel()
        model.mode = .pin
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 1.2, y: 0.5)), .none)
    }

    func testPinAndStud() {
        let model = WallEditorModel()
        model.mode = .pin
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 0.2, y: 0.3)), .placePin(NormalizedPoint(x: 0.2, y: 0.3)))
        model.mode = .stud
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 0.4, y: 0.9)), .placeStudLine(x: 0.4))
    }

    func testNGZoneNeedsTwoTapsAndNormalizesCorners() {
        let model = WallEditorModel()
        model.mode = .ngZone
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 0.6, y: 0.8)), .waitingForSecondPoint)
        XCTAssertEqual(model.pendingPoints.count, 1)
        XCTAssertEqual(
            model.handleTap(at: NormalizedPoint(x: 0.2, y: 0.1)),
            .placeNGZone(NormalizedPoint(x: 0.2, y: 0.1), NormalizedPoint(x: 0.6, y: 0.8))
        )
        XCTAssertTrue(model.pendingPoints.isEmpty)
    }

    func testCalibrationAndModeChangeClearsPending() {
        let model = WallEditorModel()
        model.mode = .calibrate
        _ = model.handleTap(at: NormalizedPoint(x: 0.1, y: 0.5))
        model.mode = .pin
        XCTAssertTrue(model.pendingPoints.isEmpty)

        model.mode = .calibrate
        _ = model.handleTap(at: NormalizedPoint(x: 0.1, y: 0.5))
        XCTAssertEqual(
            model.handleTap(at: NormalizedPoint(x: 0.6, y: 0.5)),
            .calibrate(NormalizedPoint(x: 0.1, y: 0.5), NormalizedPoint(x: 0.6, y: 0.5))
        )
    }

    func testGridAnchorReturnsToBrowse() {
        let model = WallEditorModel()
        model.mode = .gridAnchor
        XCTAssertEqual(model.handleTap(at: NormalizedPoint(x: 0.3, y: 0.5)), .setGridAnchor(x: 0.3))
        XCTAssertEqual(model.mode, .browse)
    }

    func testSnapToGrid() {
        // 写真の幅は画面で400pt。0.02 = 8pt 離れていれば吸い付く、0.1 = 40pt なら吸い付かない
        XCTAssertEqual(WallEditorModel.snappedX(0.27, gridLines: [0.25, 0.5], transform: transform), 0.25)
        XCTAssertEqual(WallEditorModel.snappedX(0.35, gridLines: [0.25, 0.5], transform: transform), 0.35)
        XCTAssertEqual(WallEditorModel.snappedX(0.35, gridLines: [], transform: transform), 0.35)
    }

    @MainActor
    func testHitTestPrefersPins() throws {
        let container = try AppSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let wall = WallSurface(name: "テスト")
        context.insert(wall)
        let stud = WallAnnotation(kind: .studLine, x: 0.5, y: 0, endX: 0.5, endY: 1)
        let pin = WallAnnotation(kind: .pin, x: 0.5, y: 0.5)
        let zone = WallAnnotation(kind: .ngZone, x: 0.1, y: 0.1, endX: 0.2, endY: 0.2)
        wall.annotations.append(contentsOf: [stud, pin, zone])

        let model = WallEditorModel()
        // 写真の中心(200,400) → ピン
        XCTAssertEqual(model.hitTest(CGPoint(x: 205, y: 405), annotations: wall.annotations, transform: transform)?.id, pin.id)
        // 間柱ラインの上の方 → 間柱
        XCTAssertEqual(model.hitTest(CGPoint(x: 203, y: 320), annotations: wall.annotations, transform: transform)?.id, stud.id)
        // NGゾーンの中（x 40〜80, y 320〜340）
        XCTAssertEqual(model.hitTest(CGPoint(x: 60, y: 330), annotations: wall.annotations, transform: transform)?.id, zone.id)
        // 何もないところ
        XCTAssertNil(model.hitTest(CGPoint(x: 350, y: 450), annotations: wall.annotations, transform: transform))
    }
}
