import Foundation

/// ビス・下穴・アンカーの判定結果
public enum FasteningResult: Hashable, Codable, Sendable {
    case screw(ScrewRecommendation)
    case anchor(AnchorRecommendation)

    public var displayTitle: String {
        switch self {
        case .screw(let s): return s.displayTitle
        case .anchor(let a): return a.displayTitle
        }
    }

    /// 履歴・買い物メモ用の1行まとめ
    public var summaryLine: String {
        switch self {
        case .screw(let s):
            guard let pilot = s.pilotHole else { return s.displayTitle }
            return "\(s.displayTitle)／下穴 \(MMFormatter.string(pilot.drillBitMM))mm"
        case .anchor(let a):
            return a.displayTitle
        }
    }

    public var restorationLevel: RestorationLevel {
        switch self {
        case .screw(let s): return s.lengthMM == nil ? .none : .puttyRequired
        case .anchor(let a): return a.restorationLevel
        }
    }
}

/// 入力と結果のセット（履歴に保存するときに使う）
public struct FasteningCalculation: Hashable, Codable, Sendable {
    public let input: FasteningInput
    public let result: FasteningResult

    public init(input: FasteningInput, result: FasteningResult) {
        self.input = input
        self.result = result
    }
}

/// タブ2「ビス・下穴ナビ」の入口
public enum FasteningAdvisor {
    public static func advise(_ input: FasteningInput) -> FasteningResult {
        switch input.target {
        case .gypsumBoardOnly(let board):
            return .anchor(AnchorAdvisor.recommend(board: board, load: input.load))
        case .twoByFour, .oneByFour, .studBehindGypsum:
            return .screw(ScrewCalculator.recommend(input))
        }
    }

    public static func calculate(_ input: FasteningInput) -> FasteningCalculation {
        FasteningCalculation(input: input, result: advise(input))
    }
}
