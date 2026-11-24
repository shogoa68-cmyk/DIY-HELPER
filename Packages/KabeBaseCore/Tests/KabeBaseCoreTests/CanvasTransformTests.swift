import XCTest
@testable import KabeBaseCore

final class CanvasTransformTests: XCTestCase {
    // 縦長の画面(400×800)に横長の写真(2000×1000)
    private let base = CanvasTransform(viewSize: CGSize(width: 400, height: 800), imageSize: CGSize(width: 2000, height: 1000))

    func testFittedRect() {
        XCTAssertEqual(base.fittedRect, CGRect(x: 0, y: 300, width: 400, height: 200))
        XCTAssertEqual(base.imageRect, base.fittedRect)
    }

    func testPointConversionRoundTrip() throws {
        let v = base.viewPoint(for: NormalizedPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(v, CGPoint(x: 200, y: 400))
        let n = try XCTUnwrap(base.normalizedPoint(for: CGPoint(x: 100, y: 350)))
        XCTAssertEqual(n.x, 0.25, accuracy: 1e-9)
        XCTAssertEqual(n.y, 0.25, accuracy: 1e-9)
    }

    func testZoomAroundCenterKeepsCenter() {
        let z = base.zoomed(by: 2, anchor: CGPoint(x: 200, y: 400))
        XCTAssertEqual(z.zoom, 2)
        XCTAssertEqual(z.imageRect, CGRect(x: -200, y: 200, width: 800, height: 400))
        XCTAssertEqual(z.viewPoint(for: NormalizedPoint(x: 0.5, y: 0.5)), CGPoint(x: 200, y: 400))
    }

    func testZoomAroundAnchorKeepsAnchorFixed() throws {
        let anchor = CGPoint(x: 100, y: 380)
        let before = try XCTUnwrap(base.normalizedPoint(for: anchor))
        let z = base.zoomed(by: 3, anchor: anchor)
        let after = z.viewPoint(for: before)
        XCTAssertEqual(after.x, anchor.x, accuracy: 1e-9)
        XCTAssertEqual(after.y, anchor.y, accuracy: 1e-9)
    }

    func testZoomIsLimited() {
        XCTAssertEqual(base.zoomed(by: 100, anchor: .zero).zoom, CanvasTransform.zoomRange.upperBound)
        XCTAssertEqual(base.zoomed(by: 0.1, anchor: .zero).zoom, 1)
    }

    func testClampedLimitsPan() {
        var t = base.zoomed(by: 2, anchor: CGPoint(x: 200, y: 400))
        t = t.panned(by: CGSize(width: 1000, height: 1000)).clamped()
        XCTAssertEqual(t.pan.width, 200)   // (800 − 400) / 2
        XCTAssertEqual(t.pan.height, 0)    // 写真の高さ400 < 画面800 なので動かさない
        XCTAssertEqual(base.panned(by: CGSize(width: 50, height: 50)).clamped().pan, .zero)
    }

    func testZeroSizes() {
        let t = CanvasTransform(viewSize: .zero, imageSize: CGSize(width: 100, height: 100))
        XCTAssertEqual(t.fittedRect, .zero)
        XCTAssertNil(t.normalizedPoint(for: .zero))
    }
}
