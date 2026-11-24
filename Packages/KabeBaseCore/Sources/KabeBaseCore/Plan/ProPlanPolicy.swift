import Foundation

/// 無料プランとProプランの制限ルール
public enum ProPlanPolicy {
    /// 無料プランで登録できる壁の数
    public static let freeMaxWalls = 2
    /// 無料プランで1つの壁に置けるピンの数
    public static let freeMaxPinsPerWall = 10

    public static func canAddWall(currentWallCount: Int, isPro: Bool) -> Bool {
        isPro || currentWallCount < freeMaxWalls
    }

    public static func canAddPin(currentPinCount: Int, isPro: Bool) -> Bool {
        isPro || currentPinCount < freeMaxPinsPerWall
    }

    /// あと何面登録できるか（nil = 無制限）
    public static func remainingWalls(currentWallCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeMaxWalls - currentWallCount)
    }

    /// あと何個ピンを置けるか（nil = 無制限）
    public static func remainingPins(currentPinCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeMaxPinsPerWall - currentPinCount)
    }
}
