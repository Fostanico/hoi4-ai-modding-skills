# HOI4 AI Modding Skills

一组让 AI 根据自然语言创建、维护和调试《钢铁雄心 IV》MOD 的 Agent Skills，适用于 Codex、Claude Code、Gemini CLI，以及支持自定义 Skills 的 ChatGPT 和 Claude。

## 包含内容

- `hoi4-content-builder`：把自然语言需求转换为完整、可玩的 MOD 内容。
- `hoi4-pdx-modding`：提供 PDX 脚本规则、原版核对方法、参考资料和静态校验工具。
- `hoi4-review-debug`：负责代码审查、日志排错、版本迁移、性能检查和测试流程。

建议三个 skill 一起安装。

## 安装

从 [GitHub Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases) 下载完整包或单独的 skill ZIP，并按平台放置：

- Codex：复制到个人的 `$HOME/.agents/skills/` 或项目的 `.agents/skills/`。
- Claude Code：复制到 `~/.claude/skills/` 或项目的 `.claude/skills/`。
- Gemini CLI：复制到 `~/.gemini/skills/`、`~/.agents/skills/` 或对应的工作区目录，然后运行 `/skills reload`。
- ChatGPT、Claude 等网页版：在平台支持自定义 Skills 时，分别上传三个单独的 skill ZIP。

目录内必须保留 `SKILL.md` 以及相邻的 `references/`、`workflows/`、`assets/` 和 `scripts/`。

## 使用

直接向 AI 描述想制作或修改的 MOD，并尽量提供目标游戏版本、MOD 路径、依赖 MOD、所需语言和预期玩法。例如：

> 为 HOI4 1.19.2 制作一组可重复决议：消耗政治点提高战争支持度，包含英文、简体中文、俄文和日文本地化，并在完成后检查日志。

Skills 会指导 AI 先核对目标版本的原版文件和文档，再生成代码、补齐跨文件引用并执行静态检查。涉及启动 Steam 或游戏测试时，AI 应先征得用户同意。

## 开源协议

本项目采用 [CC BY-SA 4.0](LICENSE)。复制、修改或再发布时，请保留署名和 [ATTRIBUTION.md](ATTRIBUTION.md)，注明修改，并以相同协议分享改编内容。本协议不授予 Paradox Interactive、其他 MOD 或第三方素材的任何权利。

## 致谢

特别感谢：

- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn)：其 CC BY-SA 4.0 开发资料为通用工作流提供了重要参考。
- 秋起图书馆（Steam Workshop 项目 `3445449478`）：其社区教程与工具资料为内容核对和参考体系提供了重要帮助。

完整来源与改编说明见 [ATTRIBUTION.md](ATTRIBUTION.md)。
