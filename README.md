# HOI4 AI Modding Skills

简体中文 | [English](README_EN.md) | [日本語](README_JA.md) | [Русский](README_RU.md) | [한국어](README_KO.md)

一套专为《钢铁雄心 IV》Mod 开发打造的组合式 Agent Skills，适配 **Codex、Google Antigravity、Cursor、Claude Code、Gemini CLI 与 ChatGPT**。这套套件**重心放在既有 Mod 的维护、排错、重构与持续完善**——帮你吃透庞杂工程、理顺跨文件依赖、调优性能并精准定位崩溃；同时完整保留了**从自然语言构想直接生成新功能乃至整套 Mod** 的能力。

你可以直接用日常语言描述想法，由 AI 负责拆解脚本、界面、素材与多语言链路；熟悉 PDX 脚本的作者也能借它建立代码审查、跨文件追踪、性能排查与崩溃定位的标准流程。

想系统了解如何和 AI 协作开发 HOI4 Mod（从需求表达、脚本与存档设计，到 GUI、着色器、多语言、排错与发布交付），请阅读通用开发指南：
[简体中文](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.zh-CN.md) |
[English](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.en.md) |
[日本語](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ja.md) |
[Русский](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ru.md) |
[한국어](skills/hoi4-pdx-modding/assets/user-guides/hoi4-modding-guide.ko.md)。
该指南面向人类读者按需取阅，技能默认只保留交付入口，避免在常规编码时白白占满上下文。

仓库同时内置两款**完全物理分离**的零依赖本地 MCP 服务器：
- **只读取证助手 `hoi4_local`**（随 Codex Plugin 一同打包）：负责本机探测 HOI4 安装、跨文件追踪标识符、轻量校验 Git 变更、读取日志与检查媒体元数据，全程只读、不联网、零改动风险。详见 [本地插件与 MCP 助手](docs/LOCAL_MCP_PLUGIN.md)。
- **可选实机测试助手 `hoi4_desktop`**（默认关闭、按需启用）：面向没有内置桌面 Computer Use 的客户端（如 Google Antigravity、Cursor、Claude Code、Gemini CLI），通过硬编码进程白名单安全地截取和操作 HOI4、Paradox Launcher 与 Steam 窗口。详见 [可选本地桌面控制 MCP 配置指南](docs/DESKTOP_MCP_SETUP.md)。

## 三套 Skills 如何分工

| Skill | 核心专长 |
| --- | --- |
| `hoi4-review-debug` | 既有 Mod 体检、跨文件 Mod Doctor、日志与崩溃诊断、性能调优、兼容性审查、玩法平衡、UX 与资源审计 |
| `hoi4-pdx-modding` | PDX 语法与作用域、变量与存档生命周期、跨文件契约、多语言本地化、版本迁移、技术文档、注释与静态校验 |
| `hoi4-content-builder` | 从自然语言构建事件、决议、国策、人物、民族精神、MIO、GUI、AI、OOB、地图、音乐、模型与完整系统 |

**请将三套 Skill 一并安装。** 它们像同一座工坊里的三道工序：`content-builder` 负责把创意做成完整功能，`pdx-modding` 守住语法、版本与接口契约，`review-debug` 负责查错、回归和实机验证。三者彼此引用规则与参考文档，成套安装才能跑通完整链路。

## 快速安装

### Codex：一键安装 Skills + 只读 MCP 插件

在 Windows 上克隆或解压本仓库后，于仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

脚本会将插件安装到当前用户的本地应用数据目录，并通过 Codex CLI 完成注册，全程不触碰游戏文件、不启动 Steam，也不上传任何本地数据。装完后**新建一个 Codex 任务**，三套 Skills 和五个只读本地工具就会立即就位；日后拉取仓库更新时，重跑同一条命令即可刷新。

环境要求：Windows、Python 3、Codex CLI（若装有 `ffprobe`，媒体工具还会顺带读取音视频流信息）。详情见 [本地插件与 MCP 助手](docs/LOCAL_MCP_PLUGIN.md)。

### 通用方式：安装三套 Skills

从 [Releases](https://github.com/Fostanico/hoi4-ai-modding-skills/releases) 下载完整发布包或直接克隆仓库，将 `skills/` 下的三个目录原样复制到以下任一位置：

- **项目级**（随 Mod 仓库同行）：`<MOD_ROOT>/.agents/skills/`
- **用户级**（多项目共用）：`$HOME/.agents/skills/`

请保持每个 Skill 目录内的 `SKILL.md`、`references/`、`workflows/`、`assets/`、`scripts/` 和 `agents/` 相对结构完整。

- **Codex / ChatGPT**：Codex 通常会自动发现更新（未生效时重启即可），可用 `/skills` 查看列表并用 `$hoi4-review-debug` 显式调用；ChatGPT 桌面版可在侧栏 Skills 页面查看。详见 [OpenAI Skills 文档](https://learn.chatgpt.com/docs/build-skills)。
- **Cursor**：自动发现项目级 `.agents/skills/`、`.cursor/skills/` 及用户级 `~/.agents/skills/`、`~/.cursor/skills/`。刷新或重开 Agent 后即可自动匹配，也可在对话中输入 `/` 按名称调用。Skills 会注入给当前选定的任意模型；如需在 Cloud Agents 中使用个人目录，请在设置中开启 Skills 同步。详见 [Cursor Agent Skills 文档](https://cursor.com/docs/skills)。
- **Google Antigravity / Claude Code / Gemini CLI**：支持按各平台目录安装三套 Skills，并可按需接入 `hoi4_local` 只读 MCP 与 `hoi4_desktop` 实机测试 MCP。

各客户端完整路径、插件配置与打包分发规范，见 [安装与共享指南](docs/INSTALLATION.md)。

## 实战提示词示例

**接手或维护既有 Mod（先诊断、后动手）：**

> `$hoi4-review-debug` 帮我审查这个 Mod。先读项目技术文档和相关玩家文案，再系统检查跨文件引用、变量生命周期、周期性性能、图标、本地化与依赖兼容性。先提交带证据的清单和分批修复方案，暂不修改文件。

**排查日志与崩溃（给出版本、依赖与最新日志）：**

> 分析这份 `error.log`，把问题按本 Mod、依赖 Mod、原版和可选媒体分开归类，按根因合并重复报错，给出每组的定位证据和最小修复方案。

**开发全新功能（直接说出玩法目标与约束）：**

> `$hoi4-content-builder` 为 HOI4 1.20 制作一组可重复决议，包含 AI 权重以及英文、简体中文、俄文、日文与韩文本地化。先核对当前原版语法，完成后对改动文件跑静态校验。

日常对话里无需每次手动点名 Skill——当你的请求匹配 `SKILL.md` 里的场景描述时，兼容客户端会自动选用对应技能；显式写出名称更适合固定流程的深度审查或专项排错。

## 核心工作流

三套技能共享同一套[工作流边界](skills/hoi4-pdx-modding/references/workflow-boundaries.md)：复用依然有效的已有证据，局部改动只复验受影响范围，文档随真实契约同步更新；实机短测把准备与还原一并计入时间预算，按问题选用最顺手的当前会话、测试存档或新局；一旦你喊停，AI 会立刻收手并给出简明交接。

### 1. 体检与重构既有 Mod

1. 先读项目技术文档、交接记录和玩家可见文案，吃透设计的真实意图。
2. 沿事件、决议、effects、triggers、变量、flags、本地化与 GUI/GFX 梳理完整的跨文件调用链。
3. 将确定性 Bug、兼容性隐患、性能瓶颈和需要作者拍板的玩法权衡分门别类。
4. 需要审批时，在动第一行代码前先交付证据与分阶段方案。
5. 获批后严守约定边界实施改动，按改动体量匹配校验深度（小改直接审 diff，常规改动校验变更文件，大改动跑跨文件审计），同时标清哪些表现还需进游戏目视确认。

### 2. 日志与崩溃定位

1. 按根因归并 `error.log`，优先解决解析失败、作用域错位、装备/意识形态缺失和本地化键冲突。
2. 结合日志时间戳、当前启用播放集和崩溃前玩家操作还原真实执行路径，避免被最后一条无关日志带偏。
3. 必要时解析 Windows minidump，清楚标明判断置信度与尚缺的证据。
4. 涉及 WinDbg、Ghidra、完整内存转储、附加进程或硬件断点时实行分级授权，每进入更高权限阶段前先征得你的明确同意。

### 3. 从想法构建新内容

1. 将自然语言需求整理成清晰的功能范围、状态归属、资源清单、AI 策略、兼容规则和验收标准。
2. 对照目标游戏版本的原版文档、实际原版消费者及真实启用的依赖核验语法与 token。
3. 基于已验证的模板与多文件套件一次性接通脚本、GFX、素材与多语言文案，不留断链或孤立定义。
4. 按改动范围完成编码、引用和文档核对；需要实机验证时严格遵守授权与预算。

## 能力覆盖面

- **脚本与状态**：PDX 语法、作用域链、事件目标、变量与 flag 生命周期
- **核心玩法系统**：事件、决议、国策、民族精神、人物、MIO、装备、科技、AI 与 OOB
- **性能与热路径**：高频 `on_actions`、全局遍历排查，以及事件驱动与分批处理改造
- **多语言体系**：UTF-8 BOM 编码、重复键排查、颜色与图标标记、格式化变量、scope functions 与多语言模板
- **界面与资源**：GUI/GFX 注册、决议/精神/特质图标、纹理路径、音频、加载图 DDS 规范、具名王牌与定制特工肖像
- **兼容与演进**：原版及大型魔改依赖兼容分支、游戏大版本迁移与旧存档安全演进
- **体验与工程交付**：玩法循环、数值平衡、AI 可用性与反制反馈、技术文档、可读注释与发布前检查
- **深度诊断**：`error.log` 归因、崩溃转储、WinDbg 及授权下的进阶原生分析

## 工程底座

- **真实对话回归集**：`evals/real-dialogue-regression.json` 沉淀了匿名化处理后的真实开发任务，用 SHA-256 指纹保留来源追溯，同时保护所有私人会话与项目隐私。
- **Mod Doctor 2**：支持自动解析当前 playset、仅审计 Git 变更、对比历史基线、配置有期限的抑制规则，按 Text / JSON / Markdown / SARIF 输出，并将确定性缺陷与启发式线索分开列报。
- **多文件实战套件**：覆盖常见内容链路以及“科技解锁装备”“游戏规则开局初始化”等完整闭环。
- **模板机器清单**：`assets/template-manifest.json` 逐项登记每个模板的目标版本、原版来源消费者、验证日期与必查项，并由校验器保证全量登记、无一遗漏。
- **按需媒体审计**：结合消费场景、DDS 元数据与显式引用排查空间占用，仅在显式查重或内容比对时计算哈希，妥善保留加载图、mipmap、cubemap 与模型材质的专属要求。

## 证据原则与安全边界

- **以当前版本实证为准**：Skills 要求 AI 优先核对目标版本的原版代码、随游戏生成的文档、实际启用的依赖与玩家可见文案；Wiki 和社区教程用来启发思路、提供线索，最终结论落在本机当前版本上。
- **静态检查与实机验证各司其职**：静态检查负责守住语法、引用、编码和接线；GUI 渲染、MIO 交互、复杂作用域与跨 Mod 兼容行为需要进游戏确认。
- **敏感操作先沟通、后执行**：凡涉及启动 Steam、操控游戏窗口、安装调试工具、逆向分析、附加进程或采集完整内存，AI 都会先说明目的、范围与风险，得到你的同意后再动手。

## 开源协议与致谢

本项目采用 [CC BY-SA 4.0](LICENSE) 协议开源。复制、改编或再分发时，请保留署名与 [ATTRIBUTION.md](ATTRIBUTION.md)、注明改动，并以相同协议分享衍生作品。本协议仅适用于本仓库发布的 Skill 内容，游戏本体、其他 Mod 及第三方素材的权利归其各自版权方所有。

特别致谢：
- [Millennium Dawn](https://github.com/MillenniumDawn/Millennium-Dawn)：其公开开发资料为本套件的兼容性规范、工程结构与高级工作流奠定了坚实参考。
- 秋起图书馆（Steam Workshop 项目 `3445449478`）：其社区教程与工具资料极大丰富了本套件的内容核对与参考体系。

完整来源与改编记录见 [ATTRIBUTION.md](ATTRIBUTION.md)。
