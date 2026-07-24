# HOI4 AI Modding Skills

一组供 AI 读取的《钢铁雄心 IV》MOD 开发 Agent Skills，适用于 Codex、Claude
Code、Gemini CLI，以及支持自定义 Skills 的 ChatGPT 和 Claude。

它既可以把没有 PDX 脚本经验的用户用自然语言描述的创意制作成可玩的 MOD，也可以
辅助有经验的开发者审查、维护、迁移和调试既有工程。Skills 要求 AI 核对目标版本的
原版文件、已启用依赖和玩家可见文本，而不是仅凭旧教程或内部变量名猜测。

## 包含内容

- `hoi4-content-builder`：完整 MOD 开发流程，以及事件、决议、国策、角色、理念、
  MIO、GUI、AI、OOB、地图、音乐、模型和高级系统的模板与可组合套件。
- `hoi4-pdx-modding`：PDX 语法、scope 与生命周期、跨文件引用、本地化、兼容性、
  性能、版本迁移、技术文档、交接内容和静态校验工具。
- `hoi4-review-debug`：完善既有 MOD、跨文件 Mod Doctor、玩法/平衡/UX 审查、图标
  与资源审计、日志和崩溃转储分析，以及经过逐级授权的 WinDbg、Ghidra、完整用户态
  转储和硬件数据断点诊断流程。

建议三个 skill 一起安装。

## 安装

从 [GitHub Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases) 下载完整包或单独的 skill ZIP，并按平台放置：

- Codex：复制到个人的 `$HOME/.agents/skills/` 或项目的 `.agents/skills/`。
- Claude Code：复制到 `~/.claude/skills/` 或项目的 `.claude/skills/`。
- Gemini CLI：复制到 `~/.gemini/skills/`、`~/.agents/skills/` 或对应的工作区目录，然后运行 `/skills reload`。
- ChatGPT、Claude 等网页版：在平台支持自定义 Skills 时，分别上传三个单独的 skill ZIP。

目录内必须保留 `SKILL.md` 以及相邻的 `references/`、`workflows/`、`assets/` 和 `scripts/`。
各平台的详细目录与发布注意事项见 [安装与共享指南](docs/INSTALLATION.md)。

## 使用

直接向 AI 描述新 MOD、既有工程或具体故障，并尽量提供目标游戏版本、MOD 路径、
依赖 MOD、所需语言和预期玩法。

新内容示例：

> 为 HOI4 1.19.2 制作一组可重复决议：消耗政治点提高战争支持度，包含英文、
> 简体中文、俄文和日文本地化，并在完成后检查日志。

既有工程示例：

> 审查这个 MOD 的事件调用、变量生命周期、周期性性能、本地化、图标和依赖兼容性，
> 区分必须修复的问题与需要我批准的设计选择，暂时不要修改代码。

崩溃分析会区分日志相关性与原生调用路径。涉及安装工具、逆向分析、启动 Steam、
附加到游戏进程或采集完整内存时，AI 必须说明下一阶段并单独取得用户授权。

## 开源协议

本项目采用 [CC BY-SA 4.0](LICENSE)。复制、修改或再发布时，请保留署名和 [ATTRIBUTION.md](ATTRIBUTION.md)，注明修改，并以相同协议分享改编内容。本协议不授予 Paradox Interactive、其他 MOD 或第三方素材的任何权利。

## 致谢

特别感谢：

- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn)：其 CC BY-SA 4.0 开发资料为通用工作流提供了重要参考。
- 秋起图书馆（Steam Workshop 项目 `3445449478`）：其社区教程与工具资料为内容核对和参考体系提供了重要帮助。

完整来源与改编说明见 [ATTRIBUTION.md](ATTRIBUTION.md)。
