# Snappy

macOS 用ウィンドウマネージャー。[Divvy](https://mizage.com/divvy/) のクローン。

グリッドで領域を選んでショートカットキーを割り当て、ウィンドウを即座に移動・リサイズします。

![Snappy Screenshot](docs/screenshot.png)

## 機能

- **グリッド選択** — 6×4 グリッドをドラッグして好きな領域を指定
- **ショートカット登録** — 領域ごとにキーコンボを自由に割り当て
- **即時反映** — キーを押すと最前面のウィンドウが指定領域にスナップ
- **メニューバー常駐** — Dock に表示されないバックグラウンドアプリ
- **Liquid Glass UI** — macOS 26 のデザイン言語に準拠
- **ログイン時自動起動** — 設定画面からオン/オフ切り替え可能

## 動作環境

- macOS 26.0 以降
- Apple Silicon / Intel どちらも対応

## ビルド方法

### 必要なもの

- Xcode 26 以降
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### 手順

```bash
git clone https://github.com/katsuma/snappy.git
cd snappy
xcodegen generate
open Snappy.xcodeproj
```

Xcode で Signing & Capabilities を開き、Development Team を自分の Apple ID に設定してから **Run** (⌘R)。

## 初回セットアップ

1. アプリを起動するとメニューバーにアイコンが表示される
2. アイコンをクリック → **Preferences…**
3. **General** タブ → "Open System Settings…" をクリック
4. **プライバシーとセキュリティ → アクセシビリティ** で Snappy を許可
5. 設定画面に戻ると "Access granted" に変わる

## 使い方

### ショートカットの追加

1. **Shortcuts** タブ → **New** ボタン
2. 名前を入力（例: `Left Half`）
3. グリッドをドラッグして領域を選択
4. キーレコーダーをクリックしてキーコンボを入力（例: `⌘←`）

### ウィンドウを移動する

登録したショートカットキーを押すだけ。最前面のウィンドウが指定領域にスナップされます。

## アーキテクチャ

```
Snappy/
├── App/
│   ├── SnappyApp.swift        # @main エントリーポイント
│   └── AppDelegate.swift      # メニューバー・設定ウィンドウ管理
├── Models/
│   ├── Shortcut.swift         # ショートカットのデータモデル
│   ├── GridRegion.swift       # グリッド領域 (6×4)
│   └── KeyCombo.swift         # キーコード + モディファイア
├── Services/
│   ├── HotkeyManager.swift    # Carbon RegisterEventHotKey でグローバルホットキー登録
│   ├── WindowMover.swift      # AXUIElement API でウィンドウ移動・リサイズ
│   └── ShortcutStore.swift    # JSON 永続化 (~/Library/Application Support/Snappy/)
└── Views/
    ├── PreferencesView.swift  # 設定ウィンドウ (TabView)
    ├── GeneralView.swift      # アクセシビリティ・ログイン設定
    ├── ShortcutsView.swift    # ショートカット一覧
    ├── ShortcutRowView.swift  # 1行分のショートカット編集 UI
    ├── GridPickerView.swift   # 6×4 グリッド (Canvas + DragGesture)
    └── KeyRecorderView.swift  # キー入力キャプチャ (NSViewRepresentable)
```

**技術的なポイント:**
- グローバルホットキーは Carbon の `RegisterEventHotKey` + `InstallEventHandler` を使用。C コールバックからは `Unmanaged` でインスタンスを復元
- ウィンドウ操作は `AXUIElement` API。NSScreen (左下原点) と AX 座標系 (主画面左上原点) の変換に注意
- App Sandbox は無効（AXUIElement と Carbon ホットキーの要件）

## 開発時の注意

アクセシビリティ権限はバイナリのコード署名に紐づくため、ビルドのたびに権限が無効になる場合があります。Xcode から直接 Run する場合は発生しませんが、もし「Access required」に戻った場合は以下を実行してください：

```bash
tccutil reset Accessibility com.katsuma.Snappy
```

その後アプリを再起動して再度許可します。

## ライセンス

MIT
