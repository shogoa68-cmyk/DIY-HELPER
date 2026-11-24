import Foundation
import Observation
import KabeBaseCore

/// タブ3の画面の状態
@Observable
final class TensionPostModel {
    enum AdjusterChoice: Hashable {
        case preset(AdjusterPreset)
        case custom

        var title: String {
            switch self {
            case .preset(let p): return p.displayName
            case .custom: return "カスタム"
            }
        }

        var subtitle: String {
            switch self {
            case .preset(let p): return "天井高 −\(MMFormatter.string(p.deductionMM))mm"
            case .custom: return "差し引き値を入力"
            }
        }
    }

    /// 画面に出す結果
    enum Outcome: Equatable {
        /// まだ入力がない
        case empty
        case failure(String)
        case success(TensionPostCalculation)
    }

    static let maxMeasurements = 6
    static let postCountRange = 1...10

    let adjusterChoices: [AdjusterChoice] = AdjusterPreset.presets.map { AdjusterChoice.preset($0) } + [AdjusterChoice.custom]

    var adjusterChoice: AdjusterChoice = .preset(.labrico2x4)
    var customDeductionText = ""
    /// 左・中央・右の3か所から始める
    var heightTexts: [String] = ["", "", ""]
    var postCount = 1

    var isCustomAdjuster: Bool { adjusterChoice == .custom }

    var adjuster: AdjusterPreset? {
        switch adjusterChoice {
        case .preset(let p):
            return p
        case .custom:
            guard let delta = MeasurementParser.value(from: customDeductionText) else { return nil }
            return .custom(deductionMM: delta)
        }
    }

    var canAddMeasurement: Bool { heightTexts.count < Self.maxMeasurements }

    func addMeasurement() {
        guard canAddMeasurement else { return }
        heightTexts.append("")
    }

    func measurementLabel(for index: Int) -> String {
        switch index {
        case 0: return "左"
        case 1: return "中央"
        case 2: return "右"
        default: return "\(index + 1)か所目"
        }
    }

    var outcome: Outcome {
        let parsed = MeasurementParser.values(from: heightTexts)
        if let bad = parsed.invalidIndices.first {
            return .failure("「\(measurementLabel(for: bad))」の数字が読み取れません。")
        }
        guard !parsed.values.isEmpty else { return .empty }
        guard let adjuster else {
            return .failure("カスタムの差し引き値（mm）を入力してください。")
        }
        let input = TensionPostInput(measuredHeightsMM: parsed.values, adjuster: adjuster, postCount: postCount)
        do {
            let result = try TensionPostCalculator.calculate(input)
            return .success(TensionPostCalculation(input: input, result: result))
        } catch let error as TensionPostError {
            return .failure(error.errorDescription ?? "計算できませんでした。")
        } catch {
            return .failure("計算できませんでした。")
        }
    }
}
