# 開発引き継ぎ仕様書：DIY支援iOSアプリ『KabeBase（仮）』

## 1. コンセプト

| エンジン | 内容 | 役割 |
|---|---|---|
| NICHE-002（フロー型・集客） | 日本のホームセンター規格に特化した「ビス・下穴・アンカー＆2×4突っ張り計算ナビ」 | 売り場・作業中のユーザーを獲得 |
| NICHE-001（ストック型・定着） | 壁の下地・間柱マップ＆賃貸原状回復ログ | 計算結果をピンとして記録 → 継続利用・Pro課金 |

## 2. 技術要件

- iOS 17.0+（iPhone優先、iPadは副次）／Swift 5.9+／SwiftUI
- SwiftData、外部サーバーなし・100%オフライン
- 写真は Documents/WallPhotos に JPEG 保存、SwiftData には **ファイル名のみ** 保持
  （アプリ更新でコンテナの絶対パスが変わるため、フルパスは保存しない）
- StoreKit 2（買い切り Pro／年額）
- 登録不要・プリセットボタン中心・単位は mm 統一

## 3. 画面構成（4タブ）

1. **壁マップ**：部屋一覧 → 壁面キャンバス（ズーム・パン）、2点キャリブレーション、303/455mm グリッド＋オフセット、アノテーション（間柱ライン／NGゾーン／施工ピン）
2. **ビス・下穴ナビ**：取付材 × 相手材 × 荷重 → ビス長・種類・下穴径・アンカー。「壁マップに記録」「買い物メモに保存」
3. **2×4突っ張り計算**：天井高（複数箇所）× アジャスター → カット長・定尺・カット依頼メモ
4. **履歴・原状回復ログ**：施工ピン一覧、原状回復フィルタ、計算履歴・買い物チェックリスト

## 4. 規格マスタ・計算ロジック（実装：`Packages/KabeBaseCore`）

### 4.1 マスタ（`DIYStandards`）
- 1×4：19×89mm／2×4：38×89mm／合板・集成材：9, 12, 15, 18, 24mm
- 石膏ボード：9.5mm, 12.5mm／間柱ピッチ：303, 455mm／間柱奥行き：105mm
- ビス長：25, 32, 38, 41, 45, 51, 65, 75, 90mm
- ドリル径：1.5, 2.0, 2.5, 3.0, 3.2, 3.5, 4.0mm
- 2×4定尺：6F 1829／8F 2438／10F 3048／12F 3658mm

### 4.2 ビス長（`ScrewCalculator`）
- 手前の層 = 取付材厚 t1 ＋ 石膏ボード厚（間柱の場合）
- 最小長 = 手前の層 ＋ 20mm、最大長 = 手前の層 ＋ 相手材厚 t2 − 2mm
- 理想長 = 手前の層 ＋ clamp(t2 × 0.7, 20, 30) ＋ 荷重補正（〜20kg: +5、20kg超: +10）、ただし最大長以下
- 範囲内の市販長から理想長に最も近いもの（同距離なら長い方）
- 範囲内が無い場合：突き抜けない最長のもの（`insufficientEmbed` として警告）、それも無ければ `noCandidate`
- 木材で t1 ≤ 19mm または材端打ち → スリムビス（φ3.3）、それ以外はコーススレッド（φ3.8、90mm は φ4.2）
- 相手材が「石膏ボードのみ」→ ビスではなくアンカー判定へ

### 4.3 下穴（`PilotHoleCalculator`）
- 下穴径 = ビス外径 × 比率の中央値（軟木 0.6〜0.7 → 0.65、堅木 0.7〜0.8 → 0.75）
- 市販ビット径の最も近い値へ（同距離なら細い方）

### 4.4 石膏ボードアンカー（`AnchorAdvisor`）
| 荷重 | 推奨 | 原状回復 |
|---|---|---|
| 〜3kg | ピンフック | 画鋲・ピン穴のみ |
| 〜10kg | ねじ込み式ボードアンカー | パテ補修要 |
| 〜20kg | トグルアンカー | パテ補修要 |
| 20kg超 | 非推奨（間柱を探す／突っ張り柱） | — |

### 4.5 2×4突っ張り（`TensionPostCalculator`）
- カット長 = 測った天井高の **最小値** − Δ（1mm未満切り捨て）
- Δ：ラブリコ 2×4 = 95mm、ディアウォール = 45mm、カスタム可
- 3か所未満の計測・5mm超のばらつき・定尺超過で警告。メーカー説明書確認の注意文を常時表示

## 5. SwiftData データモデル（実装：`KabeBase/Models`）

enum 型の値は、検索（`#Predicate`）で扱いやすいよう **rawValue の文字列** で保存し、計算プロパティで型付きアクセスする。

```
Room 1 ──cascade──▶ * WallSurface 1 ──cascade──▶ * WallAnnotation * ◀──nullify── 0..1 DiyCalcRecord
```

| モデル | 主なプロパティ |
|---|---|
| `Room` | id, name, isRental, memo, sortOrder, createdAt, walls |
| `WallSurface` | id, name, room, photoFileName, imagePixelWidth/Height, calibrationAX/AY/BX/BY/RealMM（→ `calibration: ScaleCalibration?`）, studPitchMM, gridOffsetMM, isGridVisible, createdAt, updatedAt, annotations |
| `WallAnnotation` | id, wall, kindRaw（studLine / ngZone / pin）, x, y, endX, endY（正規化座標 0〜1）, title, note, studMaterialRaw（木/軽天）, ngReasonRaw（配線/配管）, fastenerName, anchorTypeRaw, loadKg, restorationRaw, isRestored, createdAt, calcRecord |
| `DiyCalcRecord` | id, kindRaw（fastening / tensionPost）, createdAt, title, summary, payload（入力＋結果の JSON）, isFavorite, isInShoppingList, isPurchased, annotations |

## 6. 課金設計

| 機能 | 無料 | Pro（買い切り ¥980〜¥1,480想定） |
|---|---|---|
| ビス・下穴・アンカー計算 | 無制限 | お気に入り材・カスタム規格保存 |
| 2×4突っ張り計算 | 無制限 | 複数柱まとめ・カット指示画像書き出し |
| 壁マップ・間柱記録 | 壁 2面まで（ピン 10件/面） | 無制限＋原状回復リスト出力 |

制限ロジックは `ProPlanPolicy` に実装済み。

## 7. 実装ステップ

1. ✅ Step 1：雛形・SwiftData モデル・計算エンジン・XCTest
2. ✅ Step 2：タブ2・タブ3 の SwiftUI 画面（プリセットチップ選択式）。「壁マップに記録」ボタンは Step 4 まで無効表示
3. ✅ Step 3：タブ1 壁マップ
   - 部屋一覧 → 壁一覧 → 壁マップ。写真は PhotosPicker で取り込み、長辺3000pxに縮めて保存
   - モード：見る（印をタップで編集）／ピン／間柱（グリッドに20pt以内なら吸着）／NGゾーン（2点）／縮尺（2点＋実寸）
   - グリッド設定：表示切替・303/455mm・基準位置（5mm刻み or 写真の間柱をタップ）
   - 座標変換は `CanvasTransform`（ピンチ位置を中心にズーム、パンは写真が画面外へ出ない範囲に制限）
   - 写真を差し替えると縮尺はリセット（印の位置は残す）。壁・部屋を消すと写真ファイルも削除
   - 無料プランの壁数・ピン数制限は Step 4 で接続
4. Step 4：計算→ピン1タップ転記、タブ4、StoreKit 2 Pro 制限

## 注意

ビス長・アンカー耐荷重・アジャスター差し引き値は一般的な目安。アプリ内には「製品表示・メーカー説明書を確認」の注意書きを必ず表示すること。
