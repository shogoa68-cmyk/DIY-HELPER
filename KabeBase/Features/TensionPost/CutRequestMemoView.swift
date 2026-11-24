import SwiftUI
import UIKit

/// ホームセンターのカットカウンターで、店員さんに見せる用の大きな文字のメモ
struct CutRequestMemoView: View {
    let memo: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var proStore
    @State private var didCopy = false
    @State private var isPaywallPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(memo)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .lineSpacing(8)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
            .navigationTitle("カット依頼メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        UIPasteboard.general.string = memo
                        didCopy = true
                    } label: {
                        Label(didCopy ? "コピーしました" : "コピー", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    }
                    Spacer()
                    imageExportButton
                    Spacer()
                    ShareLink(item: memo) {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sensoryFeedback(.success, trigger: didCopy) { _, newValue in newValue }
        }
        .paywallSheet(isPresented: $isPaywallPresented, reason: "カット指示の画像書き出しは Pro 機能です。")
        // 画面を明るいままにして見せやすくする
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

extension CutRequestMemoView {
    /// Pro：カット指示を画像にして共有
    @ViewBuilder
    var imageExportButton: some View {
        if proStore.isPro, let image = Self.renderImage(memo: memo) {
            ShareLink(item: image, preview: SharePreview("カット指示", image: image)) {
                Label("画像", systemImage: "photo")
            }
        } else {
            Button {
                isPaywallPresented = true
            } label: {
                Label("画像（Pro）", systemImage: "photo")
            }
        }
    }

    /// ImageRenderer：SwiftUI の画面をそのまま画像にする仕組み
    @MainActor
    static func renderImage(memo: String) -> Image? {
        let card = VStack(alignment: .leading, spacing: 12) {
            Text(memo)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .lineSpacing(8)
                .foregroundStyle(.black)
            Text("KabeBase で作成")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .padding(32)
        .frame(width: 720, alignment: .leading)
        .background(Color.white)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

#Preview {
    CutRequestMemoView(memo: "【木材カットのお願い】\n材料：2×4材（38×89mm） 8F（2438mm）\nカット寸法：2305mm × 2本\n（ラブリコ 2×4アジャスター用／天井高 2400mm − 95mm）")
        .environment(ProStore(previewIsPro: true))
}
