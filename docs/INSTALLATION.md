# HOI4 AI Modding Skills 安装与共享指南

## 套件构成

这套工具包以**既有 Mod 的维护、排错、重构与持续完善**为重心，同时保留了**从自然语言生成全新内容与完整 Mod** 的全链路能力，由三个紧密配合的 Agent Skills 组成：

- **`hoi4-review-debug`**：专注既有 Mod 的日志排查、跨文件审计、版本迁移、性能优化，以及经你授权的实机验证；
- **`hoi4-pdx-modding`**：守住 PDX 语法、目录规范、目标版本核验与静态校验的底线；
- **`hoi4-content-builder`**：把自然语言玩法构想直接生成脚本、素材、界面与多语言齐全的新功能或完整 Mod。

**请始终将三套 Skill 成套安装。** 它们彼此引用规则、模板与交接流程；装齐三者才能让“设计 → 实现 → 验收”闭环运转。只需直接描述想要的玩法、规则和素材，无需先啃 PDX 脚本；至于某个 Mod 专属的变量、flag、依赖和编码约定，留在该项目自身的技术文档里即可，通用 Skills 始终保持轻盈与可复用。

## 如何分发与发布

1. **优先分发仓库源码与版本化 Release**，避免直接丢出无出处、无版本的压缩包。
2. **默认提供包含三套 Skill 的总包**，在发布说明里写清版本号、对应提交与包体大小（仅当发布渠道要求或排查传输损坏时再附校验和）。若目标平台只允许逐个上传，可额外附带三个同版本独立 ZIP，并提醒使用者一次装齐。
3. **保留完整元信息**：随包保留 `LICENSE`、`ATTRIBUTION.md` 以及每个 Skill 的完整目录层级。
4. **严守素材版权边界**：绝不将 Paradox 原版文件、Workshop 教程、其他 Mod 资源或个人本机路径打进发布包；原版与第三方文件仅在本机用于核验。
5. **跟进游戏大版本**：每次 HOI4 大版本更新后，对照新原版复核 `references/template-catalog.md` 中的原版消费者，并在 release notes 中写明实测的 HOI4 build。

## 各平台安装方式

### ChatGPT

在支持 Personal Skills 的账户中，进入个人头像 → **Skills** → **Create** → **Upload from your computer**，依次上传同一 Release 中的三个 Skill ZIP 并确认全部启用。装好后即可在 Skills 页面分享给工作区成员或生成链接。套餐支持与管理员开关以 [OpenAI Skills 官方说明](https://help.openai.com/en/articles/20001066-skills-in-chatgpt) 为准；上传与使用第三方包前，仍建议自行核对来源与脚本内容。

### Codex

- **用户级安装**：将三个 Skill 目录放入 `$CODEX_HOME/skills/`。
- **项目级安装**：将它们放入目标 Mod 的 `.agents/skills/` 并纳入 Git 管理，保持如下结构：

```text
.agents/skills/
  hoi4-content-builder/SKILL.md
  hoi4-pdx-modding/SKILL.md
  hoi4-review-debug/SKILL.md
```

刷新或重开任务后，直接用自然语言提出需求即可；项目根目录的 `AGENTS.md` 用来沉淀该项目长期生效的规范与文档入口。

#### 进阶：安装带只读本地工具的 Codex Plugin

仓库根目录本身就是完整的 Codex 插件源，将三套 Skills 与只读本地 MCP 助手 `hoi4_local` 打包在一起，适合需要在本机探测 HOI4 安装、追踪标识符、校验 Git 变更、查看日志与媒体元数据的用户。完整安装命令与安全边界见 [本地插件与 MCP 助手](LOCAL_MCP_PLUGIN.md)。

> **提示**：完成本地插件安装或刷新后，请**新建一个 Codex 任务**。已在进行的旧会话会锁定启动时的工具表，新任务才能加载刚更新的 Skills 与 MCP 工具。

### Cursor

Cursor Agent 会自动发现项目级 `.agents/skills/<skill-name>/`、`.cursor/skills/<skill-name>/`，以及用户级 `~/.agents/skills/<skill-name>/`、`~/.cursor/skills/<skill-name>/`。将同一 Release 的三个 Skill 目录原样复制到任一位置即可——项目目录方便随 Mod 同步协作，用户目录方便跨 Mod 复用。

刷新或重开 Agent 后，Cursor 会按任务自动匹配 Skill，也可在对话中输入 `/` 按名称显式调用。Skills 会随当前选定的任意模型生效；若要在 Cloud Agents 中使用个人 `~/.cursor/skills/`，请在 Cursor 设置中开启 Skills 同步。需要本机只读取证或实机测试能力时，可在 `.cursor/mcp.json` 中按需接入 `hoi4_local` 或 `hoi4_desktop`。最新路径与远程规则见 [Cursor Agent Skills 官方文档](https://cursor.com/docs/skills)。

### Claude Code / claude.ai

- **Claude Code**：将三个目录复制到 `~/.claude/skills/<skill-name>/`（用户级）或 `.claude/skills/<skill-name>/`（项目级），Claude 会依据 `description` 自动加载，也支持显式调用。详见 [Claude Code Skills 文档](https://code.claude.com/docs/en/slash-commands)。
- **claude.ai**：可在 **Settings → Features** 上传自定义 Skill ZIP；套餐与运行环境规则以 [Anthropic Agent Skills 说明](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) 为准。

### Gemini CLI / Google Antigravity

- **Gemini CLI**：自动发现用户级 `~/.gemini/skills/`、`~/.agents/skills/` 与工作区 `.gemini/skills/`、`.agents/skills/`。复制三个目录后运行 `/skills reload` 即可生效，也支持 `/skills link <path> --scope user|workspace` 或 `gemini skills install <repository-url>`。详见 [Gemini CLI Skills 官方文档](https://geminicli.com/docs/cli/using-agent-skills/)。
- **Google Antigravity**：可在 `~/.gemini/config/plugins/` 下将三套 Skills 与 `mcp-server/hoi4_mcp.py` 组合成只读本地插件；若需要在 Antigravity、Cursor、Claude Code 或 Gemini CLI 等不含内置桌面 Computer Use 的客户端中让 AI 协助完成 HOI4 实机验收，可额外按需启用独立的进程白名单桌面 MCP `hoi4_desktop`，详见 [可选本地桌面控制 MCP 配置指南](DESKTOP_MCP_SETUP.md)。

## 开源许可说明

整套 Skills 统一采用 **CC BY-SA 4.0** 许可：仓库中的通用指导吸收并改写了 Millennium Dawn（CC BY-SA 4.0）的公开工程资料，遵循相同协议分享能让衍生作品合规、省心。该协议允许自由复制、修改与商用，只需保留署名、注明修改并以相同协议发布改编部分。

统一采用 CC BY-SA 4.0 也避免了“文档一套协议、脚本另一套协议”带来的合规困扰；未来若独立工具代码彻底剥离 ShareAlike 衍生来源，再考虑单独采用 MIT 也不迟。本协议仅覆盖本仓库发布的 Skill 内容，Paradox Interactive、其他 Mod 及第三方素材均保留其原有版权。
