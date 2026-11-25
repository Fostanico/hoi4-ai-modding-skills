# HOI4 AI Modding Skills インストール・共有ガイド

[简体中文](INSTALLATION.md) | [English](INSTALLATION_EN.md) | 日本語 | [Русский](INSTALLATION_RU.md) | [한국어](INSTALLATION_KO.md)

## パッケージ構成

このツールキットは**既存 MOD の保守・診断・リファクタリング・継続的改善を主軸**としつつ、**自然言語から新機能や MOD 全体を制作する一連の能力**も備えた 3 つの Agent Skills で構成されています。

- **`hoi4-review-debug`**：既存 MOD のログ調査、ファイル横断監査、バージョン移行、性能改善、および同意を得た実機検証を担当します。
- **`hoi4-pdx-modding`**：PDX 構文、ディレクトリ規則、対象ビルドの仕様確認、静的検証を守ります。
- **`hoi4-content-builder`**：自然言語の遊び方アイデアから、スクリプト・素材・UI・多言語翻訳まで繋がった新機能や MOD 全体を組み立てます。

**必ず 3 つの Skills をまとめて導入してください。** 互いのルール・テンプレート・引き継ぎ手順を参照し合うため、3 つ揃えて初めて「設計 → 実装 → 検証」が一気通貫で機能します。PDX スクリプトを書かずに要望やルール、見た目をそのまま伝えられます。個別 MOD に固有の変数・flag・依存関係・文字コード規約はその MOD 側の技術文書に残し、共通 Skills は汎用で軽快に保ちます。

## 配布・リリース時のルール

1. **ソースコードとバージョン付き Release で配布する**：出所やバージョンの分からない圧縮ファイルだけの配布は避けます。
2. **3 つの Skills をまとめた総合パッケージを既定のダウンロードにする**：リリースノートにバージョン、元コミット、ファイルサイズを記します（チェックサムは配布先の要件や破損調査が必要なときに添えます）。1 つずつしかアップロードできないプラットフォーム向けには、同一リリースの個別 ZIP 3 本を併置し、すべて導入するよう案内します。
3. **メタデータと階層を保つ**：`LICENSE`、`ATTRIBUTION.md`、各 Skill のディレクトリ構成をそのまま残します。
4. **権利境界を守る**：Paradox バニラファイル、Workshop チュートリアル、他 MOD の素材、個人のローカルパスは配布物に含めません。バニラや第三者ファイルは手元での検証にのみ使います。
5. **大型アップデートに追従する**：HOI4 の大型パッチごとに `references/template-catalog.md` のバニラ参照先を見直し、確認済みビルドをリリースノートへ明記します。

## クライアント別の導入手順

### ChatGPT

Personal Skills に対応するアカウントで、プロフィール → **Skills** → **Create** → **Upload from your computer** を開き、同じ Release の 3 つの Skill ZIP を順にアップロードしてすべて有効にします。導入後は Skills ページからワークスペース共有やリンク発行が行えます。対象プランや管理者設定は [OpenAI Skills 公式ヘルプ](https://help.openai.com/en/articles/20001066-skills-in-chatgpt) を確認してください。第三者パッケージを使う前には出典とスクリプトをご自身でも確認するのが安心です。

### Codex

- **ユーザー単位**：3 つの Skill ディレクトリを `$CODEX_HOME/skills/` に配置します。
- **プロジェクト単位**：対象 MOD の `.agents/skills/` に配置して Git で管理し、次の階層を保ちます。

```text
.agents/skills/
  hoi4-content-builder/SKILL.md
  hoi4-pdx-modding/SKILL.md
  hoi4-review-debug/SKILL.md
```

再読み込みまたは新しいタスクを開けば、自然言語で HOI4 MOD の依頼を始められます。プロジェクト固有の長期ルールや文書への入口はリポジトリ直下の `AGENTS.md` にまとめます。

#### 任意：読み取り専用ローカルツール付きの Codex Plugin を入れる

リポジトリのルート自体が、3 つの Skills と読み取り専用ローカル MCP `hoi4_local` を一体化した Codex Plugin ソースになっています。HOI4 インストール検出、識別子追跡、Git 変更検証、ログ閲覧、メディア情報取得を手元で活かしたい場合に最適です。導入コマンドと安全設計は [ローカルプラグインと MCP ヘルパー](LOCAL_MCP_PLUGIN_JA.md) をご覧ください。

> **ヒント**：ローカルプラグインの導入・更新後は**新しい Codex タスクを開いてください**。進行中の既存タスクは起動時のツール一覧を固定しているため、更新分は新しいタスクから反映されます。

### Cursor

Cursor Agent はプロジェクト内の `.agents/skills/<skill-name>/`・`.cursor/skills/<skill-name>/`、およびユーザー配下の `~/.agents/skills/<skill-name>/`・`~/.cursor/skills/<skill-name>/` を自動検出します。同じ Release の 3 ディレクトリをいずれかへコピーしてください（プロジェクト配置は MOD と一緒に管理でき、ユーザー配置は複数 MOD で使い回せます）。

Agent を開き直すか更新すれば自動選択され、チャットで `/` から名前を指定して呼び出すこともできます。選択中の任意のモデルで利用でき、Cloud Agents で `~/.cursor/skills/` を使う場合は Cursor 設定で Skills 同期をオンにします。ローカル取証や許可付き実機テストを加えたいときは `.cursor/mcp.json` に `hoi4_local` や `hoi4_desktop` を登録できます。最新仕様は [Cursor Agent Skills 公式ドキュメント](https://cursor.com/docs/skills) を参照してください。

### Claude Code / claude.ai

- **Claude Code**：`~/.claude/skills/<skill-name>/`（ユーザー単位）または `.claude/skills/<skill-name>/`（プロジェクト単位）に 3 ディレクトリをコピーします。`description` に応じた自動ロードと明示呼び出しの両方に対応します。参考：[Claude Code Skills ドキュメント](https://code.claude.com/docs/en/slash-commands)。
- **claude.ai**：**Settings → Features** からカスタム Skill ZIP をアップロードできます。対象プランや実行環境の仕様は [Anthropic Agent Skills ガイド](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) をご確認ください。

### Gemini CLI / Google Antigravity

- **Gemini CLI**：ユーザー配下の `~/.gemini/skills/`・`~/.agents/skills/`、ワークスペース配下の `.gemini/skills/`・`.agents/skills/` を認識します。3 ディレクトリを配置して `/skills reload` を実行するほか、`/skills link <path> --scope user|workspace` や `gemini skills install <repository-url>` も利用できます。参考：[Gemini CLI Skills 公式ドキュメント](https://geminicli.com/docs/cli/using-agent-skills/)。
- **Google Antigravity**：`~/.gemini/config/plugins/` 配下に 3 つの Skills と `mcp-server/hoi4_mcp.py` をまとめて読み取り専用ローカルプラグインとして組み込めます。Antigravity・Cursor・Claude Code・Gemini CLI などデスクトップ Computer Use を内蔵しないクライアントで実機検証を任せたいときは、プロセスホワイトリスト付きの独立サーバー `hoi4_desktop` をオンデマンドで有効化してください。手順は [ローカルデスクトップ制御 MCP 設定ガイド](DESKTOP_MCP_SETUP_JA.md) にまとめています。

## ライセンス方針

本パッケージ全体は **CC BY-SA 4.0** で統一しています。汎用ガイドの基盤に Millennium Dawn（CC BY-SA 4.0）の公開開発資料の整理・翻案が含まれるため、ShareAlike に沿って同一ライセンスで共有する方が自然かつ明快です。クレジット保持、変更点の明記、同一ライセンスでの再共有を守れば、複製・改変・商用利用が可能です。

文書とスクリプトを単一ライセンスに揃えることで、利用者の確認負担も減らせます。将来的に独立スクリプトから ShareAlike 由来部分を完全に分離した場合は、独立コードのみ MIT を再検討する余地があります。ライセンスの適用範囲は本リポジトリで公開する Skill 内容に限り、Paradox Interactive や他 MOD・第三者素材の権利は各権利者に帰属します。
