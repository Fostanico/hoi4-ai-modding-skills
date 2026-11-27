# 任意導入ローカルデスクトップ実機テスト MCP（`hoi4_desktop`）設定ガイド

[简体中文](DESKTOP_MCP_SETUP.md) | [English](DESKTOP_MCP_SETUP_EN.md) | 日本語 | [Русский](DESKTOP_MCP_SETUP_RU.md) | [한국어](DESKTOP_MCP_SETUP_KO.md)

`hoi4_desktop`（`mcp-server/hoi4_desktop_mcp.py`）は、Windows デスクトップ向けの組み込み Computer Use を持たない **非 Codex クライアント**（**Google Antigravity・Cursor・Claude Code・Gemini CLI・Windsurf・Cline** 等）に向けた**汎用標準 MCP サーバー**です。既定では無効にしておき、[test-mod.md](../skills/hoi4-content-builder/workflows/test-mod.md) に沿った許可付き実機テストを任せたいときだけオンにします。

読み取り専用の `hoi4_local`（`mcp-server/hoi4_mcp.py`）とは**物理的に分離**されています。普段の開発・レビュー・静的検証は `hoi4_local` のみで完結し、テスト終了後は `hoi4_desktop` をすぐオフに戻せます。

## 設計の特徴と安全ガード

- **標準準拠・ゼロ依存・オフライン**：標準 MCP stdio JSON-RPC 2.0 に準拠し、Python 3 標準ライブラリ＋Windows Win32 API（`user32`/`gdi32`/`kernel32`/`shell32`）と純 Python PNG エンコーダだけで動作します。`pip install` もネットワークポートも不要です。
- **ハードコードされたプロセスホワイトリスト**：検出・撮影・操作できるのは以下の HOI4 関連 5 プロセスのみで、ブラウザ・チャット・IDE などの一般ウィンドウには一切アクセスできません。
  - `hoi4.exe`
  - `paradox launcher.exe`、`dowser.exe`
  - `steam.exe`、`steamwebhelper.exe`
- **クライアント領域限定キャプチャと境界チェック**：ホワイトリスト確認済みウィンドウのクライアント領域だけを撮影します（`PrintWindow(PW_RENDERFULLCONTENT)` 優先、DX11 黒フレーム時は前面確認済みのクライアント矩形に限定した `BitBlt` へフォールバック）。クリック・ドラッグ・スクロールはすべてウィンドウ相対座標で、範囲外は即座に拒否します。
- **リアルタイム前面確認と緊急停止**：入力の直前に前面ウィンドウを再検証し、`Alt+Tab` / `Alt+F4` を禁止。マウスを画面左上隅（`x <= 4, y <= 4`）へ動かせば即座に入力を緊急停止できます。
- **HOI4 実機テストに最適化した工夫**：
  - Per-Monitor V2 DPI 対応とマルチモニター仮想デスクトップ座標マッピング
  - DirectX 互換ハードウェアスキャンコードによるホットキー送信（`` ` `` コンソール、`Space`、`Esc`）
  - `KEYEVENTF_UNICODE` による UTF-16 直注入で日本語・中国語・韓国語 IME を完全回避（`cp 100` や `pp 500` が変換されたりスペースが消えたりしません）
  - 隔離デスクトップ自己診断：`list_hoi4_windows` が `desktop_name` を返し、非 `Default` デスクトップ上で隔離実行されている場合は即座に警告
  - Steam 起動 URI は `steam://rungameid/394360` 固定かつ `confirm_user_authorized: true` 必須で、`test-mod.md` の承認・設定復元ルールを厳守

## 動作前提

1. **Windows 10 / 11 ＋ Python 3**（`py -3` または `python` が `PATH` にあること）。
2. **ボーダレスフルスクリーンまたはウィンドウモード推奨**：排他フルスクリーンでは一部ドライバが GDI / `PrintWindow` キャプチャを遮断します。
3. **権限レベルの一致**：`hoi4.exe` は通常ユーザー権限で起動してください（管理者実行すると一般権限クライアントからの `SendInput` が届きません）。

## 提供ツール（11 種）

| ツール | 種別 | 用途 |
| --- | --- | --- |
| `list_hoi4_windows` | 読み取り専用 | 可視のホワイトリスト対象ウィンドウ一覧（ハンドル・プロセス名・タイトル・クライアント寸法・前面状態・デスクトップ名） |
| `capture_hoi4_window` | 読み取り専用 | 対象ウィンドウのクライアント領域だけを PNG 撮影し、座標情報・一時ファイルパス・インライン MCP 画像を返す |
| `focus_hoi4_window` | 対話操作 | 最小化解除と前面化（バックグラウンドからのフォーカス引き継ぎ対応） |
| `click_hoi4_window` | 対話操作 | 正規化（`0.0–1.0`）・クライアント px・画像 px でウィンドウ内をクリック（直後の撮影オプション付き） |
| `drag_hoi4_window` | 対話操作 | ウィンドウ内を滑らかにドラッグ（マップ移動・スクロールバー・可動パネル） |
| `scroll_hoi4_window` | 対話操作 | 指定座標でマウスホイールを回転（ズーム・ディシジョン／国家方針一覧スクロール） |
| `send_hoi4_keys` | 対話操作 | DirectX ハードウェアスキャンコードでキー・ショートカットを送信（`Alt+Tab` / `Alt+F4` 禁止） |
| `type_hoi4_text` | 対話操作 | IME を回避する Unicode 直注入で短文を入力（上限 500 文字） |
| `lookup_hoi4_console_commands` | 読み取り専用 | 実行前に HOI4 1.20.0 の全 458 コンソールコマンド・変数を検索（構文・例・AI 影響・製品版可否） |
| `run_hoi4_console_command` | 対話操作 | **`hoi4.exe` 専用**：コンソール（`` ` ``）を開き 1 行コマンドを実行、任意で閉じて撮影（構文ミスの注意喚起付き） |
| `launch_hoi4_steam` | 対話操作 | ユーザーの明示承認後に `steam://rungameid/394360` を起動（`confirm_user_authorized: true` 必須） |

## クライアント設定例

`<REPO_ROOT>` を本リポジトリ（またはプラグイン）のローカル絶対パスへ置き換えてください。普段は無効にし、実機検証時だけ有効にする運用がおすすめです。

### 1. Google Antigravity（推奨：独立トグルプラグイン化）

`~/.gemini/config/plugins/hoi4-desktop-control/` に `plugin.json`、`mcp_config.json`、`mcp-server/` の `hoi4_desktop_mcp.py`・`hoi4_console_catalog.py`・`hoi4_console_commands.json` を置き、`mcp_config.json` に次を記載します。

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "py",
      "args": [
        "-3",
        "-u",
        "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control\\mcp-server\\hoi4_desktop_mcp.py"
      ],
      "cwd": "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control"
    }
  }
}
```

設定後は Antigravity の **Plugins Manager** からいつでもワンクリックでオン／オフでき、読み取り専用の `hoi4_local` や 3 つの Skills へ影響しません。

### 2. Cursor / Claude Code / Gemini CLI / Windsurf / Cline

各クライアントの MCP 設定ファイル（`.cursor/mcp.json`、`.mcp.json`、`~/.claude.json`、`~/.gemini/settings.json` 等）の `mcpServers` に追加します。

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "cmd.exe",
      "args": [
        "/d",
        "/s",
        "/c",
        "call",
        "<REPO_ROOT>\\mcp-server\\launch_desktop.cmd"
      ]
    }
  }
}
```

リポジトリ内のテンプレート [mcp-server/hoi4_desktop.mcp.example.json](../mcp-server/hoi4_desktop.mcp.example.json) もそのまま流用できます。

### 3. Codex

Codex デスクトップ版はネイティブの Computer Use を標準搭載しているため、既定の `.mcp.json` には読み取り専用の `hoi4_local` のみを登録しています。

## オフライン自己点検（デスクトップ副作用ゼロ）

リポジトリのルートで実行します。

```powershell
python scripts/test-desktop-mcp-server.py
```

プロセスホワイトリスト拒否、範囲外座標の遮断、純 Python PNG 往復変換、`null` 引数フォールバック、コンソール検索と構文警告、JSON-RPC ハンドシェイク、全 11 ツール定義、未承認 `launch_hoi4_steam` 拒否を一括検証します。Steam の起動やデスクトップ操作は一切発生しません。
