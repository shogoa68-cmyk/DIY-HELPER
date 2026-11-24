import SwiftUI
import UIKit

/// ホームセンターのカットカウンターで、店員さんに見せる用の大きな文字のメモ
struct CutRequestMemoView: View {
    let memo: String
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

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
                    ShareLink(item: memo) {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sensoryFeedback(.success, trigger: didCopy) { _, newValue in newValue }
        }
        // 画面を明るいままにして見せやすくする
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

#Preview {
    CutRequestMemoView(memo: "【木材カットのお願い】\n材料：2×4材（38×89mm） 8F（2438mm）\nカット寸法：2305mm × 2本\n（ラブリコ 2×4アジャスター用／天井高 2400mm − 95mm）")
}
