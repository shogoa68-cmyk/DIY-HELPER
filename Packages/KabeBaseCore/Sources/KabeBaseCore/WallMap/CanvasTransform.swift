import Foundation

/// 壁マップのキャンバスで「写真のどこ（正規化座標）」と「画面のどこ（ポイント）」を相互に変換する。
///
/// 画面座標 = 中心 + pan + (ぴったり表示したときの座標 − 中心) × zoom
public struct CanvasTransform: Equatable, Sendable {
    public static let zoomRange: ClosedRange<CGFloat> = 1...8

    /// キャンバスの大きさ（ポイント）
    public var viewSize: CGSize
    /// 写真のピクセルサイズ（縦横比だけ使う）
    public var imageSize: CGSize
    public var zoom: CGFloat
    public var pan: CGSize

    public init(viewSize: CGSize, imageSize: CGSize, zoom: CGFloat = 1, pan: CGSize = .zero) {
        self.viewSize = viewSize
        self.imageSize = imageSize
        self.zoom = zoom
        self.pan = pan
    }

    private var center: CGPoint { CGPoint(x: viewSize.width / 2, y: viewSize.height / 2) }

    /// 拡大していないとき、写真が画面にぴったり収まる位置
    public var fittedRect: CGRect {
        guard viewSize.width > 0, viewSize.height > 0, imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (viewSize.width - size.width) / 2,
            y: (viewSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    /// 拡大・移動したあとの写真の位置
    public var imageRect: CGRect {
        let f = fittedRect
        let c = center
        return CGRect(
            x: c.x + pan.width + (f.minX - c.x) * zoom,
            y: c.y + pan.height + (f.minY - c.y) * zoom,
            width: f.width * zoom,
            height: f.height * zoom
        )
    }

    public func viewPoint(for p: NormalizedPoint) -> CGPoint {
        let r = imageRect
        return CGPoint(x: r.minX + CGFloat(p.x) * r.width, y: r.minY + CGFloat(p.y) * r.height)
    }

    /// 画面上の点 → 写真の正規化座標。写真の外でも値は返す（0〜1の外になる）。
    public func normalizedPoint(for v: CGPoint) -> NormalizedPoint? {
        let r = imageRect
        guard r.width > 0, r.height > 0 else { return nil }
        return NormalizedPoint(x: Double((v.x - r.minX) / r.width), y: Double((v.y - r.minY) / r.height))
    }

    /// anchor（ピンチした指の位置）を中心に拡大・縮小する
    public func zoomed(by factor: CGFloat, anchor: CGPoint) -> CanvasTransform {
        guard factor > 0, factor.isFinite, zoom > 0 else { return self }
        var t = self
        let newZoom = min(max(zoom * factor, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
        let ratio = newZoom / zoom
        let c = center
        t.pan = CGSize(
            width: (anchor.x - c.x) - (anchor.x - c.x - pan.width) * ratio,
            height: (anchor.y - c.y) - (anchor.y - c.y - pan.height) * ratio
        )
        t.zoom = newZoom
        return t
    }

    public func panned(by translation: CGSize) -> CanvasTransform {
        var t = self
        t.pan = CGSize(width: pan.width + translation.width, height: pan.height + translation.height)
        return t
    }

    /// 写真が画面の外へ行きすぎないように移動量を制限する
    public func clamped() -> CanvasTransform {
        var t = self
        t.zoom = min(max(zoom, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
        let f = fittedRect
        let maxX = max(0, (f.width * t.zoom - viewSize.width) / 2)
        let maxY = max(0, (f.height * t.zoom - viewSize.height) / 2)
        t.pan = CGSize(
            width: min(max(pan.width, -maxX), maxX),
            height: min(max(pan.height, -maxY), maxY)
        )
        return t
    }
}
