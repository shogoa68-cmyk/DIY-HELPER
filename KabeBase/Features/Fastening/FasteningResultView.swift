import SwiftUI
import KabeBaseCore

/// ビス／アンカーの判定結果カード
struct FasteningResultView: View {
    let result: FasteningResult

    var body: some View {
        ResultCard {
            switch result {
            case .screw(let screw):
                ScrewResultContent(recommendation: screw)
            case .anchor(let anchor):
                AnchorResultContent(recommendation: anchor)
            }
            RestorationBadge(level: result.restorationLevel)
        }
    }
}

private struct ScrewResultContent: View {
    let recommendation: ScrewRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusBadge(status: recommendation.status)

            if let length = recommendation.lengthMM {
                VStack(alignment: .leading, spacing: 0) {
                    Text(recommendation.screwType.displayName)
                        .font(.title3.bold())
                    (Text("\(length)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                     + Text(" mm").font(.title2.bold()))
                        .accessibilityLabel("長さ \(length) ミリ")
                }

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    if let d = recommendation.diameterMM {
                        row("ビスの太さ", "φ\(MMFormatter.string(d))mm（目安）")
                    }
                    if let pilot = recommendation.pilotHole {
                        row("下穴ドリル", "\(MMFormatter.string(pilot.drillBitMM))mm")
                    }
                    if let embed = recommendation.embedDepthMM {
                        row("相手材に効く深さ", "\(MMFormatter.string(embed))mm")
                    }
                    if recommendation.range.isSatisfiable {
                        row("OKな長さ", "\(MMFormatter.string(recommendation.range.minimumMM))〜\(MMFormatter.string(recommendation.range.maximumMM))mm")
                    }
                    if !recommendation.alternativeLengthsMM.isEmpty {
                        row("ほかの候補", recommendation.alternativeLengthsMM.map { "\($0)mm" }.joined(separator: "・"))
                    }
                }
                .font(.subheadline)
            }

            ForEach(recommendation.notes, id: \.self) { note in
                NoteRow(text: note)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).fontWeight(.semibold)
        }
    }
}

private struct AnchorResultContent: View {
    let recommendation: AnchorRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let primary = recommendation.primary {
                Text("下地がないのでアンカーを使います")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(primary.displayName)
                    .font(.title2.bold())
                Text(primary.summary)
                    .font(.subheadline)
                if !recommendation.alternatives.isEmpty {
                    Text("ほかの選択肢：" + recommendation.alternatives.map(\.displayName).joined(separator: "・"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("アンカーでは支えられません", systemImage: "exclamationmark.triangle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
            }

            ForEach(recommendation.notes, id: \.self) { note in
                NoteRow(text: note)
            }
        }
    }
}

private struct StatusBadge: View {
    let status: ScrewRecommendation.Status

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var text: String {
        switch status {
        case .ok: return "条件OK"
        case .insufficientEmbed: return "効きが浅いので注意"
        case .noCandidate: return "合うビスなし"
        }
    }

    private var icon: String {
        switch status {
        case .ok: return "checkmark.circle.fill"
        case .insufficientEmbed: return "exclamationmark.triangle.fill"
        case .noCandidate: return "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch status {
        case .ok: return .green
        case .insufficientEmbed: return .orange
        case .noCandidate: return .red
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            FasteningResultView(result: FasteningAdvisor.advise(FasteningInput(attached: .oneByFour, target: .twoByFour)))
            FasteningResultView(result: FasteningAdvisor.advise(FasteningInput(attached: .oneByFour, target: .gypsumBoardOnly(.t12_5), load: .medium)))
        }
        .padding()
    }
}
