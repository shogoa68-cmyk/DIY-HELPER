import SwiftUI
import SwiftData
import KabeBaseCore

/// ピン・間柱ライン・NGゾーンの中身を編集するシート
struct AnnotationEditorView: View {
    @Bindable var annotation: WallAnnotation
    let calibration: ScaleCalibration?
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// よく使う「使ったもの」のプリセット（押すと原状回復の種類も自動で入る）
    private struct FastenerPreset: Hashable {
        let name: String
        let restoration: RestorationLevel
    }

    private static let fastenerPresets: [FastenerPreset] = [
        FastenerPreset(name: "画鋲", restoration: .pinHole),
        FastenerPreset(name: "ピンフック", restoration: .pinHole),
        FastenerPreset(name: "スリムビス", restoration: .puttyRequired),
        FastenerPreset(name: "コーススレッド", restoration: .puttyRequired),
        FastenerPreset(name: "ボードアンカー", restoration: .puttyRequired),
    ]
    private static let loadPresetsKg: [Double?] = [nil, 1, 3, 5, 10, 20]

    var body: some View {
        NavigationStack {
            Form {
                switch annotation.kind {
                case .pin: pinSections
                case .studLine: studSections
                case .ngZone: ngZoneSections
                }

                if let position = positionText {
                    Section("位置") {
                        Text(position).font(.subheadline)
                    }
                }

                Section("メモ") {
                    TextField("気づいたことなど", text: $annotation.note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button("この印を削除", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private var title: String {
        switch annotation.kind {
        case .pin: return "施工ピン"
        case .studLine: return "間柱ライン"
        case .ngZone: return "NGゾーン"
        }
    }

    // MARK: ピン

    @ViewBuilder
    private var pinSections: some View {
        Section("名前") {
            TextField("例：棚受け 左", text: $annotation.title)
        }
        Section("使ったもの") {
            FlowLayout(spacing: 8) {
                ForEach(Self.fastenerPresets, id: \.self) { preset in
                    Chip(title: preset.name, isSelected: annotation.fastenerName == preset.name) {
                        annotation.fastenerName = preset.name
                        annotation.restoration = preset.restoration
                    }
                }
            }
            TextField("例：スリムビス 45mm", text: Binding(
                get: { annotation.fastenerName ?? "" },
                set: { annotation.fastenerName = $0.isEmpty ? nil : $0 }
            ))
        }
        Section("アンカー") {
            ChipPicker(
                options: [AnchorType?.none] + AnchorType.allCases.map { Optional($0) },
                selection: $annotation.anchorType,
                title: { $0?.displayName ?? "なし" }
            )
        }
        Section("掛けた物の重さ") {
            ChipPicker(
                options: Self.loadPresetsKg,
                selection: $annotation.loadKg,
                title: { kg in kg.map { "\(MMFormatter.string($0))kg" } ?? "未設定" }
            )
        }
        Section("原状回復") {
            ChipPicker(
                options: RestorationLevel.allCases,
                selection: $annotation.restoration,
                title: { $0.displayName }
            )
            Toggle("補修済み（穴埋めが終わった）", isOn: $annotation.isRestored)
        }
    }

    // MARK: 間柱

    @ViewBuilder
    private var studSections: some View {
        Section("間柱の素材") {
            ChipPicker(
                options: StudMaterial.allCases,
                selection: Binding(
                    get: { annotation.studMaterial ?? .wood },
                    set: { annotation.studMaterial = $0 }
                ),
                title: { $0.displayName }
            )
            Text("軽量鉄骨（軽天）の場合は、木工用ビスではなく鉄骨用のビスが必要です。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: NGゾーン

    @ViewBuilder
    private var ngZoneSections: some View {
        Section("ここにあるもの") {
            ChipPicker(
                options: NGZoneReason.allCases,
                selection: Binding(
                    get: { annotation.ngReason ?? .wiring },
                    set: { annotation.ngReason = $0 }
                ),
                title: { $0.displayName }
            )
            Text("コンセントやスイッチの上下は、壁の中に電線が通っていることが多いです。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: 位置

    private var positionText: String? {
        guard let calibration else { return nil }
        let left = calibration.mm(fromNormalizedX: annotation.x)
        switch annotation.kind {
        case .pin:
            let top = annotation.y * calibration.imageHeightMM
            return "写真の左端から \(MMFormatter.string(left.rounded()))mm、上端から \(MMFormatter.string(top.rounded()))mm"
        case .studLine:
            return "写真の左端から \(MMFormatter.string(left.rounded()))mm"
        case .ngZone:
            guard let endX = annotation.endX, let endY = annotation.endY else { return nil }
            let width = (endX - annotation.x) * calibration.imageWidthMM
            let height = (endY - annotation.y) * calibration.imageHeightMM
            return "幅 約\(MMFormatter.string(width.rounded()))mm × 高さ 約\(MMFormatter.string(height.rounded()))mm"
        }
    }
}

/// 2点間キャリブレーションの「実際の長さ」を入れるシート
struct CalibrationSheet: View {
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preset: Double? = 910
    @State private var customText = ""

    private static let presetsMM: [Double?] = [303, 455, 910, 1820, nil]

    private var distanceMM: Double? {
        preset ?? MeasurementParser.value(from: customText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ChipPicker(
                        options: Self.presetsMM,
                        selection: $preset,
                        title: { mm in mm.map { "\(MMFormatter.string($0))mm" } ?? "自分で入力" }
                    )
                    if preset == nil {
                        HStack {
                            TextField("例：1000", text: $customText)
                                .keyboardType(.numberPad)
                            Text("mm")
                        }
                    }
                } header: {
                    Text("タップした2点の、実際の長さ")
                } footer: {
                    Text("メジャーを写真に写しておくか、ドアの幅など長さがわかる物を使うと正確です。写真は壁の正面からまっすぐ撮ると、ずれが少なくなります。")
                }
            }
            .navigationTitle("縮尺を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let distanceMM { onSave(distanceMM) }
                        dismiss()
                    }
                    .disabled(distanceMM == nil)
                }
            }
        }
    }
}

/// 間柱グリッドの設定シート
struct GridSettingsSheet: View {
    @Bindable var wall: WallSurface
    let onPickAnchor: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if wall.calibration == nil {
                    Section {
                        Label("グリッドを出すには、先に「縮尺」モードで写真の縮尺を設定してください。", systemImage: "ruler")
                            .font(.subheadline)
                    }
                }

                Section {
                    Toggle("グリッドを表示", isOn: $wall.isGridVisible)
                    ChipPicker(
                        options: DIYStandards.studPitchesMM,
                        selection: $wall.studPitchMM,
                        title: { "\(MMFormatter.string($0))mm" },
                        subtitle: { $0 == 455 ? "最近の住宅に多い" : "古い住宅・天井下地など" }
                    )
                } header: {
                    Text("間柱の間隔（ピッチ）")
                }

                Section {
                    Stepper(value: $wall.gridOffsetMM, in: -10_000...10_000, step: 5) {
                        Text("写真の左端から \(MMFormatter.string(wall.gridOffsetMM))mm")
                    }
                    Button("写真の間柱をタップして合わせる", systemImage: "scope") {
                        onPickAnchor()
                        dismiss()
                    }
                    .disabled(wall.calibration == nil)
                } header: {
                    Text("基準の間柱の位置")
                } footer: {
                    Text("下地センサーや下地探しピンで見つけた間柱を1本タップすると、そこから等間隔にグリッドが引かれます。")
                }
            }
            .navigationTitle("間柱グリッド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .onChange(of: wall.studPitchMM) { wall.updatedAt = .now }
            .onChange(of: wall.gridOffsetMM) { wall.updatedAt = .now }
        }
    }
}
