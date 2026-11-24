import SwiftUI
import SwiftData
import KabeBaseCore

/// 部屋の中の壁の一覧
struct RoomDetailView: View {
    @Bindable var room: Room
    @Environment(\.modelContext) private var modelContext
    @Environment(ProStore.self) private var proStore
    /// すべての部屋の壁（無料版の上限チェック用）
    @Query private var allWalls: [WallSurface]
    @State private var isAddingWall = false
    @State private var isPaywallPresented = false

    private func requestAddWall() {
        if ProPlanPolicy.canAddWall(currentWallCount: allWalls.count, isPro: proStore.isPro) {
            isAddingWall = true
        } else {
            isPaywallPresented = true
        }
    }

    private var sortedWalls: [WallSurface] {
        room.walls.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                Toggle("賃貸の部屋", isOn: $room.isRental)
            }
            Section {
                if sortedWalls.isEmpty {
                    Button {
                        requestAddWall()
                    } label: {
                        Label("壁を追加する", systemImage: "plus.rectangle.on.rectangle")
                    }
                } else {
                    ForEach(sortedWalls) { wall in
                        NavigationLink(value: wall) {
                            WallRow(wall: wall)
                        }
                    }
                    .onDelete(perform: deleteWalls)
                }
            } header: {
                Text("壁")
            } footer: {
                if let remaining = ProPlanPolicy.remainingWalls(currentWallCount: allWalls.count, isPro: proStore.isPro) {
                    Text("無料版：壁はあと\(remaining)面登録できます（全部屋で\(ProPlanPolicy.freeMaxWalls)面まで）")
                }
            }
        }
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    requestAddWall()
                } label: {
                    Label("壁を追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingWall) {
            WallFormView(existingNames: room.walls.map(\.name)) { name, pitch in
                let wall = WallSurface(name: name, studPitchMM: pitch)
                room.walls.append(wall)
            }
            .presentationDetents([.medium, .large])
        }
        .paywallSheet(
            isPresented: $isPaywallPresented,
            reason: "無料版で登録できる壁は全部屋で\(ProPlanPolicy.freeMaxWalls)面までです。"
        )
    }

    private func deleteWalls(at offsets: IndexSet) {
        let walls = sortedWalls
        for index in offsets {
            let wall = walls[index]
            wall.deletePhotoFile()
            room.walls.removeAll { $0.id == wall.id }
            modelContext.delete(wall)
        }
    }
}

private struct WallRow: View {
    let wall: WallSurface
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
            .frame(width: 56, height: 56)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(wall.name).font(.headline)
                Text(detailText).font(.caption).foregroundStyle(.secondary)
            }
        }
        .task(id: wall.photoFileName) {
            guard let name = wall.photoFileName else {
                thumbnail = nil
                return
            }
            thumbnail = await ImageStore.shared.load(fileName: name)?.byPreparingThumbnail(ofSize: CGSize(width: 112, height: 112))
        }
    }

    private var detailText: String {
        var parts = ["ピン \(wall.pins.count)個"]
        parts.append("\(MMFormatter.string(wall.studPitchMM))mmピッチ")
        if wall.photoFileName == nil {
            parts.append("写真なし")
        } else if wall.calibration == nil {
            parts.append("縮尺未設定")
        }
        return parts.joined(separator: "・")
    }
}

/// 壁を追加するフォーム
struct WallFormView: View {
    let existingNames: [String]
    let onSave: (_ name: String, _ pitchMM: Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var pitchMM: Double = 455

    private static let suggestions = ["北の壁", "南の壁", "東の壁", "西の壁", "テレビ側", "ベッド側", "窓側", "ドア側"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("壁の名前") {
                    TextField("例：テレビ側", text: $name)
                    FlowLayout(spacing: 8) {
                        ForEach(Self.suggestions.filter { !existingNames.contains($0) }, id: \.self) { suggestion in
                            Chip(title: suggestion, isSelected: trimmedName == suggestion) { name = suggestion }
                        }
                    }
                }
                Section {
                    ChipPicker(
                        options: DIYStandards.studPitchesMM,
                        selection: $pitchMM,
                        title: { "\(MMFormatter.string($0))mm" },
                        subtitle: { $0 == 455 ? "最近の住宅に多い" : "古い住宅など" }
                    )
                } header: {
                    Text("間柱の間隔")
                } footer: {
                    Text("わからなければ455mmのままでOK。あとから変えられます。")
                }
            }
            .navigationTitle("壁を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        onSave(trimmedName, pitchMM)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
