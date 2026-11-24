import Foundation

/// 写真上の位置を 0〜1 の割合で表した座標（正規化座標）。
/// 写真の大きさや画面の拡大率が変わっても、同じ場所を指せる。
public struct NormalizedPoint: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// 2点間キャリブレーション：写真上の2点と、その実際の距離（mm）から縮尺を求める。
public struct ScaleCalibration: Hashable, Codable, Sendable {
    public let pointA: NormalizedPoint
    public let pointB: NormalizedPoint
    public let realDistanceMM: Double
    public let imagePixelWidth: Double
    public let imagePixelHeight: Double
    /// 写真1ピクセルが何mmか
    public let mmPerPixel: Double

    public init?(
        pointA: NormalizedPoint,
        pointB: NormalizedPoint,
        realDistanceMM: Double,
        imagePixelWidth: Double,
        imagePixelHeight: Double
    ) {
        guard realDistanceMM > 0, imagePixelWidth > 0, imagePixelHeight > 0 else { return nil }
        let dx = (pointB.x - pointA.x) * imagePixelWidth
        let dy = (pointB.y - pointA.y) * imagePixelHeight
        let pixels = (dx * dx + dy * dy).squareRoot()
        guard pixels >= 1 else { return nil }
        self.pointA = pointA
        self.pointB = pointB
        self.realDistanceMM = realDistanceMM
        self.imagePixelWidth = imagePixelWidth
        self.imagePixelHeight = imagePixelHeight
        self.mmPerPixel = realDistanceMM / pixels
    }

    /// 写真全体の横幅（実寸mm）
    public var imageWidthMM: Double { imagePixelWidth * mmPerPixel }
    /// 写真全体の高さ（実寸mm）
    public var imageHeightMM: Double { imagePixelHeight * mmPerPixel }

    /// 2点間の実寸距離（mm）
    public func distanceMM(from a: NormalizedPoint, to b: NormalizedPoint) -> Double {
        let dx = (b.x - a.x) * imageWidthMM
        let dy = (b.y - a.y) * imageHeightMM
        return (dx * dx + dy * dy).squareRoot()
    }

    public func mm(fromNormalizedX x: Double) -> Double { x * imageWidthMM }
    public func normalizedX(fromMM mm: Double) -> Double { mm / imageWidthMM }
}
