import SwiftUI
import SwiftData
import KabeBaseCore

/// タブ2：ビス・下穴ナビ
struct FasteningNavigatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = FasteningNavigatorModel()
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    attachedSection
                    targetSection
                    loadSection
                    if model.showsScrewOptions {
                        optionsSection
                    }

                    let calculation = model.calculation
                    FasteningResultView(result: calculation.result)
                    actionButtons(for: calculation)

                    NoteRow(text: "数値は一般的な目安です。製品パッケージの表示やメーカーの説明を必ず確認してください。", systemImage: "exclamationmark.bubble")
                }
                .padding()
                .animation(.default, value: model.isMetalSelected)
                .animation(.default, value: model.targetKind)
            }
            .navigationTitle("ビス・下穴ナビ")
            .saveToast($toastMessage)
        }
    }

    // MARK: 入力

    private var attachedSection: some View {
        InputSection(number: 1, title: "取り付ける材") {
            ChipPicker(options: AttachedMaterial.presets, selection: $model.attachedPreset, title: { $0.shortName })
            if model.isMetalSelected {
                Text("金具の厚み").font(.caption).foregroundStyle(.secondary)
                ChipPicker(
                    options: FasteningNavigatorModel.metalThicknessPresetsMM,
                    selection: $model.metalThicknessMM,
                    title: { "\(MMFormatter.string($0))mm" }
                )
            }
        }
    }

    private var targetSection: some View {
        InputSection(number: 2, title: "相手材（どこに留める？）") {
            ChipPicker(
                options: FasteningNavigatorModel.TargetKind.allCases,
                selection: $model.targetKind,
                title: { $0.title },
                subtitle: { $0.subtitle }
            )
            if model.targetKind.usesGypsum {
                Text("石膏ボードの厚み").font(.caption).foregroundStyle(.secondary)
                ChipPicker(
                    options: GypsumBoardThickness.allCases,
                    selection: $model.gypsumThickness,
                    title: { $0.displayName },
                    subtitle: { $0.usage }
                )
            }
        }
    }

    private var loadSection: some View {
        InputSection(number: 3, title: "付ける物の重さ") {
            ChipPicker(
                options: LoadClass.allCases,
                selection: $model.load,
                title: { $0.displayName },
                subtitle: { $0.examples }
            )
        }
    }

    private var optionsSection: some View {
        DisclosureGroup("詳しい条件") {
            VStack(alignment: .leading, spacing: 12) {
                if model.attached.isWood {
                    Toggle("材の端（木口の近く）に打つ", isOn: $model.isEdgeScrewing)
                }
                Text("木の硬さ（下穴の太さが変わります）").font(.caption).foregroundStyle(.secondary)
                ChipPicker(options: WoodHardness.allCases, selection: $model.woodHardness, title: { $0.displayName })
            }
            .padding(.top, 8)
        }
        .font(.subheadline)
    }

    // MARK: アクション

    private func actionButtons(for calculation: FasteningCalculation) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    save(calculation, toShoppingList: false)
                } label: {
                    Label("履歴に保存", systemImage: "bookmark")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)

                Button {
                    save(calculation, toShoppingList: true)
                } label: {
                    Label("買い物メモへ", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!calculation.result.hasPurchasableItem)
            }

            // Step 4 で壁マップのピンに転記できるようにする
            Button {} label: {
                Label("壁マップに記録（準備中）", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.bordered)
            .disabled(true)
        }
    }

    private func save(_ calculation: FasteningCalculation, toShoppingList: Bool) {
        let record = DiyCalcRecord.make(from: calculation)
        record.isInShoppingList = toShoppingList
        modelContext.insert(record)
        try? modelContext.save()
        toastMessage = toShoppingList ? "買い物メモに追加しました" : "履歴に保存しました"
    }
}

#Preview {
    FasteningNavigatorView()
        .modelContainer(try! AppSchema.makeContainer(inMemory: true))
}
