# HOI4 ローカルプラグインと読み取り専用 MCP ヘルパー（`hoi4_local`）

[简体中文](LOCAL_MCP_PLUGIN.md) | [English](LOCAL_MCP_PLUGIN_EN.md) | 日本語 | [Русский](LOCAL_MCP_PLUGIN_RU.md) | [한국어](LOCAL_MCP_PLUGIN_KO.md)

## 構成と役割

このプラグインは **3 つの Agent Skills** と **読み取り専用のローカル MCP サーバー（`hoi4_local`）** をひとまとめにしています。
- **Skills** が方法論（機能設計、バージョン確認、証拠の扱い、変更境界、引き継ぎ手順）を定めます。
- **`hoi4_local` MCP** が頻繁に使うローカル調査を、構造化された安全な読み取り専用ツールとして提供します。
- **Codex Plugin マニフェスト** が両者を単一パッケージとして管理し、導入と更新を揃えます。

`hoi4_local` の役割は手元の事実を素早く正確に届けることです。最終的な構文や挙動の判断は、対象ビルドのバニラ実装・有効な依存 MOD・ゲーム内での確認と組み合わせて行います。MCP を使わない環境でも、リポジトリ付属の PowerShell / Python / `rg` / Git スクリプトで同じ手順を実行できます。

## 6 つの読み取り専用ツール

| ツール | 機能 | 利用時のポイント |
| --- | --- | --- |
| `detect_hoi4_environment` | MOD 作業ディレクトリ、HOI4 インストール先、ユーザーデータ、ログ、Workshop を検出 | ローカルのパス全体を把握します。有効 MOD 一覧はプレイセットや `dlc_load.json` と併せて確認してください |
| `trace_hoi4_identifier` | MOD・バニラ・指定依存 MOD を横断して ID・flag・ローカライズキー・GFX 名を検索 | テキスト一致を返します。ヒット後は呼び出し側が実際に消費しているか確認します |
| `validate_hoi4_changes` | 指定パスや Git 変更分に対して軽量な PDX・ローカライズ静的検証を実行 | 変更ファイルに絞って読み取り専用で検証します。全体監査には Mod Doctor を使います |
| `read_hoi4_logs` | `error.log` や `game.log` などの末尾を有界読み取りし、重複行を集約 | ログファイルは一切消去しません。解析前にタイムスタンプが直近の起動と一致するか確認してください |
| `inspect_hoi4_media` | DDS/PNG/JPEG/GIF の寸法・形式メタデータと、`ffprobe` 導入時の音声・動画ストリーム情報を取得 | ファイルの客観仕様を返します。描画要件は各 GUI/GFX 利用側の規約と照合します |
| `lookup_hoi4_console_commands` | HOI4 1.20.0 の全 458 コンソールコマンド・調整変数を名前・別名・分類・意図で検索（導入済み `documentation/console_commands_documentation.md` も自動統合） | 製品版での可否、AI への影響、落とし穴（`eval_effect` と `effect` の違い等）や開発版専用コマンド警告を返します |

6 つのツールは **100% 読み取り専用** です。Steam や HOI4 の起動、プレイセット変更、MOD ファイルの作成・編集・削除、ゲームプロセス操作は一切行いません。画面キャプチャや入力操作を伴う実機テストには、下記のように物理分離された任意有効化サーバー `hoi4_desktop` を使います。

## 動作モデル

- **ローカル stdio 通信**：クライアントが必要に応じて子プロセスを起動し、標準入出力で 1 行 1 件の UTF-8 JSON-RPC メッセージをやり取りします。プロセス寿命はクライアントが管理し、ネットワークポートは開きません。
- **ゼロ依存・オフライン**：Python 3 標準ライブラリのみで動作し、クラウドの HOI4 コーパスや OpenAI API キーは不要です。`PATH` に `ffprobe` があれば音声・動画ストリーム情報を自動で補い、未導入なら自動で外部取得せずその旨だけを返します。

## インストールと更新

リポジトリのルート自体がプラグインソースで、`.codex-plugin/plugin.json` が単一の `skills/` と `.mcp.json` を参照します。開発時のセルフチェック：

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

Windows ではリポジトリのルートで以下を実行するだけで導入・更新が完了します。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

スクリプトは現在のユーザーのローカルアプリデータ内に独立した `hoi4-local-modding` marketplace を整備し、更新識別子を付けて Codex CLI へ自動登録します。導入・更新後は**新しい Codex タスクを開いて**最新の Skills とツールを読み込んでください。公開リリースにはプラグイン一式 ZIP に加え、非プラグイン環境向けの個別 Skill ZIP 3 本も併せて用意します。

## 安全設計とトラブルシュート

- **クリーンな通信経路**：stdout は 1 行 1 件の UTF-8 JSON-RPC のみに限定し、診断出力はすべて stderr へ流します。
- **有界スキャン**：検索はホワイトリストのテキスト拡張子に限定し、`.git`・`node_modules`・`dist` を除外したうえでファイルサイズと件数に上限を設けます。
- **ワークスペース外へのアクセス禁止**：検証とメディア検査は `mod_root` 配下のみに制限し、`..` による越境を拒否します。
- **ログ名ホワイトリスト**：`read_hoi4_logs` は登録済み HOI4 ログ名のみを読み取り、任意ファイルの閲覧を防ぎます。
- **ツールが見えないとき**：`python` / `py -3` が `PATH` にあるか確認し、新しいタスクを開き直したうえで `python scripts/test-mcp-server.py` を実行してください。

## 任意拡張：実機テスト専用デスクトップ MCP（`hoi4_desktop`）

`hoi4_local` を常に純粋な読み取り専用に保つため、画面取得とマウス／キーボード操作は**既定で無効・必要時のみ有効化**する独立サーバー `mcp-server/hoi4_desktop_mcp.py`（`hoi4_desktop`）へ切り離しています。

- **Google Antigravity・Cursor・Claude Code・Gemini CLI** など、ネイティブの Windows デスクトップ Computer Use を持たないクライアント向け
- Python 3 標準ライブラリ＋Windows Win32 API のみ、外部依存ゼロ・ネットワーク通信ゼロ
- プロセスホワイトリストを `hoi4.exe`・`Paradox Launcher`・`dowser.exe`・`Steam` にハードコードし、ブラウザやチャットアプリ、IDE には一切触れない設計
- `hoi4-content-builder/workflows/test-mod.md` のユーザー承認・短時間予算・設定復元ルールをそのまま適用

設定例、安全境界、オフライン自己点検（`python scripts/test-desktop-mcp-server.py`）は [ローカルデスクトップ制御 MCP 設定ガイド](DESKTOP_MCP_SETUP_JA.md) を参照してください。

今後の拡張予定として、有効プレイセットの解析、descriptor ロード順グラフ、より細かいログ原因帰属を計画しています。
