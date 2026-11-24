import SwiftUI
import SwiftData
import KabeBaseCore

/// タブ3：2×4突っ張り・棚計算
struct TensionPostView: View {
    private enum Field: Hashable {
        case height(Int)
        case customDeduction
    }

    @Environment(\.modelContext) private var modelContext
    @State private var model = TensionPostModel()
    @State private var toastMessage: String?
    @State private var memoToShow: String?
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    adjusterSection
                    heightSection
                    countSection
                    resultSection
                    NoteRow(text: TensionPostCalculator.disclaimer, systemImage: "exclamationmark.bubble")
                }
                .padding()
                .animation(.default, value: model.isCustomAdjuster)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("2×4突っ張り計算")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focusedField = nil }
                }
            }
            .saveToast($toastMessage)
            .sheet(item: Binding(
                get: { memoToShow.map(IdentifiedText.init) },
                set: { memoToShow = $0?.text }
            )) { item in
                CutRequestMemoView(memo: item.text)
            }
        }
    }

    // MARK: 入力

    private var adjusterSection: some View {
        InputSection(number: 1, title: "アジャスター") {
            ChipPicker(
                options: model.adjusterChoices,
                selection: $model.adjusterChoice,
                title: { $0.title },
                subtitle: { $0.subtitle }
            )
            if model.isCustomAdjuster {
                HStack {
                    Text("差し引く長さ")
                    TextField("例：95", text: $model.customDeductionText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .customDeduction)
                    Text("mm")
                }
                .font(.subheadline)
            }
        }
    }

    private var heightSection: some View {
        InputSection(number: 2, title: "天井高を測る（床〜天井）") {
            NoteRow(text: "天井は場所によって高さが違うことがあります。柱を立てる位置の左・中央・右など、3か所以上測りましょう。", systemImage: "ruler")
            ForEach(model.heightTexts.indices, id: \.self) { index in
                HStack {
                    Text(model.measurementLabel(for: index))
                        .frame(width: 64, alignment: .leading)
                    TextField("例：2400", text: $model.heightTexts[index])
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3.monospacedDigit())
                        .focused($focusedField, equals: .height(index))
                    Text("mm")
                }
            }
            if model.canAddMeasurement {
                Button("測る場所を追加", systemImage: "plus.circle") {
                    model.addMeasurement()
                    focusedField = .height(model.heightTexts.count - 1)
                }
                .font(.subheadline)
            }
        }
    }

    private var countSection: some View {
        InputSection(number: 3, title: "柱の本数") {
            Stepper(value: $model.postCount, in: TensionPostModel.postCountRange) {
                Text("\(model.postCount)本").font(.title3.bold())
            }
        }
    }

    // MARK: 結果

    @ViewBuilder
    private var resultSection: some View {
        switch model.outcome {
        case .empty:
            ResultCard {
                Label("天井高を入れると、2×4材を何mmで切ればいいか表示します。", systemImage: "arrow.up.and.down")
                    .foregroundStyle(.secondary)
            }
        case .failure(let message):
            ResultCard {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        case .success(let calculation):
            TensionPostResultView(result: calculation.result)
            actionButtons(for: calculation)
        }
    }

    private func actionButtons(for calculation: TensionPostCalculation) -> some View {
        VStack(spacing: 10) {
            Button {
                focusedField = nil
                memoToShow = calculation.result.cutRequestMemo
            } label: {
                Label("店員さんに見せる（カット依頼メモ）", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 10) {
                Button {
                    save(calculation, toShoppingList: false)
                } label: {
                    Label("履歴に保存", systemImage: "bookmark")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                Button {
                    save(calculation, toShoppingList: true)
                } label: {
                    Label("買い物メモへ", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func save(_ calculation: TensionPostCalculation, toShoppingList: Bool) {
        focusedField = nil
        let record = DiyCalcRecord.make(from: calculation)
        record.isInShoppingList = toShoppingList
        modelContext.insert(record)
        try? modelContext.save()
        toastMessage = toShoppingList ? "買い物メモに追加しました" : "履歴に保存しました"
    }
}

/// sheet(item:) で文字列を渡すための小さな入れ物
private struct IdentifiedText: Identifiable {
    let text: String
    var id: String { text }
}

/// カット長の結果カード
struct TensionPostResultView: View {
    let result: TensionPostResult

    var body: some View {
        ResultCard {
            Text("2×4材のカット長")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            (Text("\(result.cutLengthMM)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
             + Text(" mm × \(result.postCount)本").font(.title2.bold()))
                .accessibilityLabel("\(result.cutLengthMM) ミリを \(result.postCount) 本")

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("買う木材").foregroundStyle(.secondary)
                    Text(result.recommendedStock.map { "2×4 \($0.displayName)" } ?? "定尺では足りません")
                        .fontWeight(.semibold)
                }
                GridRow {
                    Text("計算に使った天井高").foregroundStyle(.secondary)
                    Text("\(MMFormatter.string(result.baseHeightMM))mm").fontWeight(.semibold)
                }
                GridRow {
                    Text("差し引き").foregroundStyle(.secondary)
                    Text("−\(MMFormatter.string(result.adjuster.deductionMM))mm（\(result.adjuster.displayName)）")
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)

            ForEach(result.warnings, id: \.self) { warning in
                NoteRow(text: warning, systemImage: "exclamationmark.triangle.fill", tint: .orange)
            }
        }
    }
}

#Preview {
    TensionPostView()
        .modelContainer(try! AppSchema.makeContainer(inMemory: true))
}
