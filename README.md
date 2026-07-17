# HOI4 AI Modding Skills

让 ChatGPT、Codex、Claude、Gemini 等 AI Agent 根据自然语言需求创建、审查和
调试《钢铁雄心 IV》MOD。当前版本：`1.1.0`。

## 这套包是什么

这套包由三个可组合 Agent Skills 组成：

- `hoi4-content-builder`：面向不会 PDX 语言的用户，把自然语言需求做成完整 MOD；
- `hoi4-pdx-modding`：提供 PDX 语言、目录、版本核验和静态验证基础；
- `hoi4-review-debug`：负责日志、审查、迁移、性能和经用户同意的实机测试。

建议三个一起安装。使用时用户只需描述玩法、题材、规则和素材，不需要先写 PDX
代码。目标 MOD 自己的变量、flag、依赖和编码约定应留在该 MOD 的技术交接文档，
不要写回通用 skills。

## 发布给别人

1. 发布仓库源代码和版本化 release，不要只发来历不明的压缩包。
2. release 同时提供总包与三个单独 skill ZIP，并公布 SHA-256。
3. 保留 `LICENSE`、`ATTRIBUTION.md` 和各 skill 的完整目录结构。
4. 不要打包 Paradox 原版文件、Workshop 教程、其他 MOD 素材或本机路径。原版和
   第三方文件只用于核验，除非其许可证明确允许再分发。
5. 每个游戏大版本重新核对 `references/template-catalog.md` 中的原版消费者，并在
   release notes 写明核验的 HOI4 build。

## ChatGPT

在支持 Personal Skills 的 ChatGPT 账户中，打开个人头像 > **Skills** >
**Create** > **Upload from your computer**，逐个上传三个 skill ZIP。安装后可以在
Skills 页面分享给 workspace 成员或生成共享链接。Personal Skills 的可用套餐和
管理员开关会变化，以 [OpenAI Skills 官方说明](https://help.openai.com/en/articles/20001066-skills-in-chatgpt)
为准；ChatGPT 会扫描上传包，但上传者和使用者仍应自行审查脚本与来源。

## Codex

个人安装：把三个 skill 目录放到 `$HOME/.agents/skills/`。项目安装：把它们放到
项目的 `.agents/skills/`，并将该目录纳入版本控制。保持结构：

```text
.agents/skills/
  hoi4-content-builder/SKILL.md
  hoi4-pdx-modding/SKILL.md
  hoi4-review-debug/SKILL.md
```

重新打开任务或刷新 skills 后，用自然语言提出 HOI4 MOD 需求即可。项目根的
`AGENTS.md` 只保存该项目长期有效的规则和交接入口。

本仓库是可被多种 Agent 读取的标准多 skill 源码包。若要在 Codex 中提供一个入口
完成整套安装，可在此基础上另行封装 Codex plugin；源码仍应保留当前三个独立 skill
目录，方便其他平台使用。

## 下载与校验

GitHub **Releases** 提供整套 ZIP、三个单独 skill ZIP 和版本对应的
`SHA256SUMS-<version>.txt`。
从 Releases 下载时，应在解压或安装前核对 SHA-256；从仓库克隆时，可直接使用
`skills/` 下的三个目录。

## Claude

Claude Code 的个人目录是 `~/.claude/skills/<skill-name>/`，项目目录是
`.claude/skills/<skill-name>/`。把三个目录分别放入其中；Claude 会根据
`description` 自动加载，也可直接调用 skill。详见
[Claude Code Skills 官方文档](https://code.claude.com/docs/en/slash-commands)。

claude.ai 可在 Settings > Features 上传自定义 skill ZIP；可用套餐、代码执行与
API/workspace 规则见
[Anthropic Agent Skills 官方说明](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)。

## Gemini CLI

Gemini CLI 可从用户级 `~/.gemini/skills/` 或 `~/.agents/skills/`，以及工作区
`.gemini/skills/` 或 `.agents/skills/` 发现 skills。复制三个目录后运行
`/skills reload`；也可用 `/skills link <path> --scope user|workspace` 做开发链接。
远程单 skill 仓库可用 `gemini skills install <repository-url>`。详见
[Gemini CLI Skills 官方文档](https://geminicli.com/docs/cli/using-agent-skills/)。

## 推荐许可证

整套 skills 建议统一使用 **CC BY-SA 4.0**。原因是现有通用指导中包含对
Millennium Dawn CC BY-SA 4.0 材料的改写与归纳，ShareAlike 要求再发布的改编
材料继续使用同一许可证。该许可证允许复制、修改和商业使用，但必须署名、标明
修改并以相同许可证分享。

统一 CC BY-SA 4.0 比“文档 CC、脚本 MIT”的混合许可更容易让普通用户正确遵守。
本建议不是法律意见；若未来完全重写并清除 ShareAlike 来源，可再评估将独立代码
改用 MIT。许可证只覆盖本仓库明确发布的 skill 内容，不授予 Paradox、Workshop
作者、其他 MOD 或素材的权利。
