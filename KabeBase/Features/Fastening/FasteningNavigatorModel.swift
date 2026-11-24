import Foundation
import Observation
import KabeBaseCore

/// タブ2の画面の状態。チップで選んだ値から、計算エンジンの入力を組み立てる。
/// （@Observable：値が変わると、それを使っている画面が自動で書き直される）
@Observable
final class FasteningNavigatorModel {
    /// 相手材の大きな分類（石膏ボードの厚みは別のチップで選ぶ）
    enum TargetKind: String, CaseIterable, Identifiable, Hashable {
        case twoByFour
        case oneByFour
        case stud
        case gypsumOnly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .twoByFour: return "2×4材"
            case .oneByFour: return "1×4材"
            case .stud: return "間柱（ボード越し）"
            case .gypsumOnly: return "石膏ボードのみ"
            }
        }

        var subtitle: String {
            switch self {
            case .twoByFour: return "38mm"
            case .oneByFour: return "19mm"
            case .stud: return "壁の中の柱"
            case .gypsumOnly: return "下地なし"
            }
        }

        var usesGypsum: Bool { self == .stud || self == .gypsumOnly }
    }

    /// よく使う金具の厚み
    static let metalThicknessPresetsMM: [Double] = [1.6, 2.0, 2.3, 3.2]

    var attachedPreset: AttachedMaterial = .oneByFour
    var metalThicknessMM: Double = 2.0
    var targetKind: TargetKind = .twoByFour
    var gypsumThickness: GypsumBoardThickness = .t12_5
    var load: LoadClass = .light
    var isEdgeScrewing = false
    var woodHardness: WoodHardness = .softwood

    var isMetalSelected: Bool {
        if case .metalBracket = attachedPreset { return true }
        return false
    }

    var attached: AttachedMaterial {
        isMetalSelected ? .metalBracket(thicknessMM: metalThicknessMM) : attachedPreset
    }

    var target: TargetMaterial {
        switch targetKind {
        case .twoByFour: return .twoByFour
        case .oneByFour: return .oneByFour
        case .stud: return .studBehindGypsum(gypsumThickness)
        case .gypsumOnly: return .gypsumBoardOnly(gypsumThickness)
        }
    }

    /// ビスの条件（端打ち・木の硬さ）を表示するか。アンカーのときは関係ない。
    var showsScrewOptions: Bool { targetKind != .gypsumOnly }

    var input: FasteningInput {
        FasteningInput(
            attached: attached,
            target: target,
            load: load,
            isEdgeScrewing: isEdgeScrewing && attached.isWood,
            woodHardness: woodHardness
        )
    }

    var calculation: FasteningCalculation { FasteningAdvisor.calculate(input) }
}
