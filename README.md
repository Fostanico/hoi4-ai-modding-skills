# HOI4 AI Modding Skills

简体中文 | [English](README_EN.md)

这是三套供 Codex、ChatGPT、Claude Code 和 Gemini CLI 使用的《钢铁雄心 IV》
Agent Skills。它们现在更侧重于维护、诊断和完善已有 MOD，同时保留从自然语言需求
开始制作新内容和完整 MOD 的能力。

这不是一份要求用户先学完 PDX 语言的教程。你可以把工程、日志和目标交给 AI，
让它沿着固定的证据链检查代码；熟悉 MOD 开发的用户也可以指定文件、约束和审批
边界，把 skills 当作代码审查、兼容性迁移和故障诊断流程使用。

## 三套 Skills

| Skill | 主要用途 |
| --- | --- |
| `hoi4-review-debug` | 完善既有 MOD、跨文件 Mod Doctor、日志与崩溃分析、性能、兼容性、玩法平衡、UX、图标和资源审计 |
| `hoi4-pdx-modding` | PDX 脚本、scope、生命周期、跨文件契约、本地化、版本迁移、技术文档、注释和静态校验 |
| `hoi4-content-builder` | 从自然语言需求制作事件、决议、国策、角色、ideas、MIO、GUI、AI、OOB、地图、音乐、模型和完整系统 |

三套 skill 可以单独使用，但一起安装时覆盖最完整。

## 在 Codex 中安装

从 [Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases)
下载完整包，或者克隆本仓库。把 `skills/` 下的三个目录复制到以下任一位置：

- 当前 MOD 仓库：`<MOD_ROOT>/.agents/skills/`
- 当前用户：`$HOME/.agents/skills/`

项目目录适合随 MOD 一起维护，用户目录适合在多个 MOD 中共用。每个 skill 目录内的
`SKILL.md`、`references/`、`workflows/`、`assets/`、`scripts/` 和
`agents/` 应保持原有相对位置。

Codex 通常会自动发现更新；没有出现时重启 Codex。在 Codex CLI 或 IDE 扩展中可用
`/skills` 查看 skills，并用 `$hoi4-review-debug` 这样的名字显式调用。ChatGPT
桌面版可以从侧栏的 Skills 页面查看。安装位置和调用方式也可参阅
[OpenAI 的 Skills 文档](https://learn.chatgpt.com/docs/build-skills)。

更完整的平台说明见 [安装与共享指南](docs/INSTALLATION.md)。

## 在 Codex 中使用

维护已有 MOD 时，可以从一次只读审查开始：

> `$hoi4-review-debug` 审查这个 MOD。先读项目技术文档和相关本地化，再检查跨文件
> 引用、变量生命周期、周期性性能、图标、本地化和依赖兼容性。先报告问题和方案，
> 不要修改文件。

处理日志时，最好同时给出 MOD 路径、目标游戏版本、启用的依赖和最新
`error.log`：

> 分析这份 `error.log`，区分本 MOD、依赖 MOD、原版和可忽略警告。按根因归组，
> 给出证据、影响范围和最小修复方案。

制作新内容时，直接说明玩法目标和边界：

> `$hoi4-content-builder` 为 HOI4 1.19 制作一组可重复决议，包含 AI 权重、英文、
> 简体中文、俄文和日文本地化。先核对当前原版语法，完成后运行静态校验。

不必每次显式写 skill 名称。任务与 `SKILL.md` 中的描述匹配时，Codex 也可以自动
选择对应 skill；显式调用更适合需要固定工作流的审计和诊断任务。

## 主要工作流

### 完善既有 MOD

1. 读取项目技术文档、交接记录和玩家可见本地化，确认功能原意。
2. 建立事件、决议、effects、triggers、变量、flags、本地化、GUI 和 GFX 的跨文件关系。
3. 区分确定性缺陷、兼容性风险、性能问题和需要作者决定的玩法选择。
4. 先给出证据和分批方案；需要审批时停在修改之前。
5. 获批后只改约定范围，运行静态检查，并说明仍需哪些游戏内测试。

### 日志与崩溃诊断

1. 按根因合并 `error.log`，优先处理解析、scope、装备、ideology 和本地化冲突。
2. 将日志时间、启用模组和崩溃时玩家行为与代码路径对应，不把最后一条日志当成原因。
3. 必要时分析 Windows minidump，并报告结论置信度和缺失证据。
4. WinDbg、Ghidra、完整用户态转储、附加进程和硬件数据断点采用分级授权；未获用户同意不进入下一阶段。

### 开发新内容

1. 把自然语言需求整理成范围、状态、资源、AI 行为、兼容性和验收标准。
2. 对照目标版本的原版文档、原版消费者和实际依赖确认语法与 token。
3. 使用模板或套件完成脚本、GFX、资源和本地化，避免留下孤立定义。
4. 检查编码、跨文件引用、注释、技术文档、日志和运行时测试清单。

## 能检查什么

- PDX 语法、scope 链、事件目标、变量和 flag 生命周期
- 事件、决议、国策、ideas、角色、MIO、装备、科技、AI 和 OOB
- `on_actions` 热路径、全局扫描和可改为事件驱动或低频执行的逻辑
- 本地化编码、重复键、颜色、图标、格式化变量、scope functions 和多语言模板
- GUI/GFX 注册、idea/decision/trait 图标、贴图路径、音频和依赖资源
- 加载图 DDS 约束、具名王牌飞行员、自定义特工特质/图标/固定肖像
- 原版与大型依赖 MOD 的兼容分支、版本迁移和保存生命周期风险
- 玩法循环、数值平衡、AI 可用性、反馈、反制手段和玩家体验
- 技术文档、交接内容、可读注释、验证记录和发布前检查
- `error.log`、crash dumps、WinDbg 与经过授权的进阶原生诊断

## 使用边界

Skills 会要求 AI 尽量核对目标版本的原版文件、随游戏安装的文档、实际启用的依赖
和玩家可见本地化。Wiki 和社区教程可以帮助定位问题，但不能代替当前版本验证。

静态检查不能证明 GUI、MIO、事件 scope 或兼容分支在游戏中一定正常。涉及启动
Steam、控制游戏、安装诊断工具、逆向分析、附加进程或采集完整内存时，应先说明
目的、风险和范围，并取得用户授权。

## 其他平台

- Claude Code：放入 `~/.claude/skills/` 或项目的 `.claude/skills/`。
- Gemini CLI：放入 `~/.gemini/skills/`、`~/.agents/skills/` 或工作区支持的目录。
- 支持上传自定义 Skill 的客户端：分别使用发行包中的单 skill ZIP。

不同客户端的发现路径会变化，安装前请核对对应平台的当前文档。

## 开源协议

本项目采用 [CC BY-SA 4.0](LICENSE)。复制、修改或再发布时，请保留署名和
[ATTRIBUTION.md](ATTRIBUTION.md)，注明修改，并以相同协议分享改编内容。本协议
不授予 Paradox Interactive、其他 MOD 或第三方素材的任何权利。

## 致谢

- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn)：其公开开发资料为兼容性、工程结构和高级工作流提供了重要参考。
- 秋起图书馆（Steam Workshop 项目 `3445449478`）：其社区教程与工具资料帮助完善了内容核对和参考体系。

完整来源与改编说明见 [ATTRIBUTION.md](ATTRIBUTION.md)。
