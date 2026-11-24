import SwiftUI
import SwiftData
import KabeBaseCore

/// 部屋・壁ごとの施工ピン一覧と、原状回復の進み具合
struct RestorationLogView: View {
    @Environment(ProStore.self) private var proStore
    @Query(filter: #Predicate<WallAnnotation> { $0.kindRaw == "pin" }, sort: \WallAnnotation.createdAt)
    private var pins: [WallAnnotation]

    @State private var filter = RestorationFilter()
    @State private var isPaywallPresented = false

    private struct PinGroup: Identifiable {
        let wall: WallSurface
        let pins: [WallAnnotation]
        var id: UUID { wall.id }
    }

    /// 部屋 → 壁 の順にまとめたピン
    private var groups: [PinGroup] {
        let filtered = pins.filter { $0.wall != nil && filter.matches($0) }
        let byWall = Dictionary(grouping: filtered) { $0.wall!.id }
        return byWall.values
            .compactMap { pins -> PinGroup? in
                guard let wall = pins.first?.wall else { return nil }
                return PinGroup(wall: wall, pins: pins)
            }
            .sorted { a, b in
                let ra = a.wall.room?.sortOrder ?? 0
                let rb = b.wall.room?.sortOrder ?? 0
                if ra != rb { return ra < rb }
                return a.wall.createdAt < b.wall.createdAt
            }
    }

    var body: some View {
        let groups = groups
        List {
            Section {
                ChipPicker(options: RestorationFilter.Level.allCases, selection: $filter.level, title: { $0.title })
                Toggle("未補修だけ表示", isOn: $filter.onlyUnrestored)
                Toggle("賃貸の部屋だけ", isOn: $filter.onlyRental)
            } footer: {
                Text(summaryText(groups.flatMap(\.pins)))
            }

            if groups.isEmpty {
                Section {
                    Text(pins.isEmpty ? "壁マップにピンを置くと、ここに一覧が出ます。" : "条件に合うピンはありません。")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(groups) { group in
                Section("\(group.wall.room?.name ?? "")／\(group.wall.name)") {
                    ForEach(group.pins) { pin in
                        PinLogRow(pin: pin)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                exportButton(entries: groups.flatMap(\.pins).map(RestorationReport.entry(for:)))
            }
        }
        .paywallSheet(isPresented: $isPaywallPresented, reason: "原状回復リストの書き出しは Pro 機能です。")
    }

    @ViewBuilder
    private func exportButton(entries: [RestorationReport.Entry]) -> some View {
        if proStore.isPro {
            ShareLink(item: RestorationReport.makeText(entries: entries)) {
                Label("リストを書き出す", systemImage: "square.and.arrow.up")
            }
            .disabled(entries.isEmpty)
        } else {
            Button {
                isPaywallPresented = true
            } label: {
                Label("リストを書き出す（Pro）", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func summaryText(_ pins: [WallAnnotation]) -> String {
        let putty = pins.filter { $0.restoration == .puttyRequired && !$0.isRestored }.count
        let pinHoles = pins.filter { $0.restoration == .pinHole && !$0.isRestored }.count
        return "未補修：パテ補修 \(putty)か所・ピン穴 \(pinHoles)か所"
    }
}

private struct PinLogRow: View {
    @Bindable var pin: WallAnnotation

    var body: some View {
        HStack(spacing: 12) {
            Button {
                pin.isRestored.toggle()
            } label: {
                Image(systemName: pin.isRestored ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(pin.isRestored ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(pin.isRestored ? "補修済み" : "未補修")
            .sensoryFeedback(.success, trigger: pin.isRestored) { _, newValue in newValue }

            if let wall = pin.wall {
                NavigationLink(value: wall) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pin.title.isEmpty ? "ピン" : pin.title)
                .font(.headline)
                .strikethrough(pin.isRestored)
            if let fastener = pin.fastenerName {
                Text(fastener).font(.subheadline).foregroundStyle(.secondary)
            }
            RestorationBadge(level: pin.restoration)
        }
    }
}
