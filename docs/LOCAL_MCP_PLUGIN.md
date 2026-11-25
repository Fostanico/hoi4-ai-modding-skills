# HOI4 本地插件与只读 MCP 助手（`hoi4_local`）

## 架构与定位

这套插件由**三套 Agent Skills** 和一个**本地只读 MCP 服务器（`hoi4_local`）**组成：
- **Skills** 负责方法论——规定如何设计功能、核验版本、收集证据、控制改动边界与组织交付；
- **`hoi4_local` MCP** 负责本机取证——把高频的只读查询封装成结构化、有边界的工具调用；
- **Codex Plugin 清单**将二者打包为一个组件，实现一键安装与同步刷新。

`hoi4_local` 的职责是快速、准确地递上本机事实；最终的语法与行为结论，仍由 AI 结合目标版本的原版消费者、启用依赖与实机观察来拍板。如果某个客户端暂不支持 MCP，仓库里的 PowerShell、Python、`rg` 与 Git 脚本同样能走通全流程。

## 五项只读工具

| 工具 | 做什么 | 使用提示 |
| --- | --- | --- |
| `detect_hoi4_environment` | 探测 Mod 工作区、HOI4 安装路径、用户数据目录、日志与 Workshop 位置 | 展示本机路径全貌；当前实际启用的 Mod 列表请结合 playset / `dlc_load.json` 确认 |
| `trace_hoi4_identifier` | 在 Mod、原版及指定依赖中精确追踪 ID、flag、本地化键与 GFX 名称 | 返回源码文本命中，拿到结果后需继续确认调用方是否真正消费该标识符 |
| `validate_hoi4_changes` | 对指定路径或 Git 变更运行轻量 PDX 与本地化静态校验 | 聚焦变更文件且绝不改写源码；全仓深度体检请使用 Mod Doctor |
| `read_hoi4_logs` | 有界读取 `error.log`、`game.log` 等日志尾部，并自动合并重复行 | 始终保留原日志不清空；分析前请先核对文件时间戳是否对应本轮运行 |
| `inspect_hoi4_media` | 读取 DDS/PNG/JPEG/GIF 的尺寸与格式元数据，并在装有 `ffprobe` 时读取音视频流 | 提供客观文件参数；实际渲染要求需对照对应 GUI/GFX 消费者规范 |

五个工具**100% 只读**：绝不启动 Steam 或 HOI4，绝不切换 playset，绝不增删改任何 Mod 文件，也绝不干预游戏进程。需要与游戏窗口交互时，请使用下方完全独立的可选桌面控制服务器 `hoi4_desktop`。

## 运行机制

- **本地 stdio 传输**：由客户端按需拉起子进程，通过标准输入/输出交换 UTF-8 JSON-RPC 消息；进程生命周期完全交由客户端托管，不监听任何网络端口。
- **零外部依赖、零联网**：仅依赖 Python 3 标准库，无需云端语料库或 OpenAI API Key。若本机 PATH 中已有 `ffprobe`，媒体工具会自动补充音视频流信息；未安装时直接标明缺失，绝不擅自下载软件。

## 安装与更新

仓库根目录即插件源，`.codex-plugin/plugin.json` 直接指向唯一的 `skills/` 与 `.mcp.json`。开发自检命令：

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

Windows 用户在仓库根目录运行即可安装或一键刷新：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

脚本会在当前用户的本地应用数据目录维护独立的 `hoi4-local-modding` marketplace，并自动写入刷新标识后通过 Codex CLI 完成注册，无需手改配置文件。安装或更新完成后，请**新建 Codex 任务**以加载最新工具表。对外发布时建议同时提供完整插件 ZIP 与三个独立 Skill ZIP，兼顾各类客户端。

## 安全防线与排查

- **纯净通道**：stdout 仅输出单行 UTF-8 JSON-RPC 消息，诊断信息一律走 stderr。
- **有界扫描**：跨文件搜索仅限白名单文本后缀，自动跳过 `.git`、`node_modules`、`dist` 等目录，并限制单文件体积与返回条数。
- **工作区防越界**：校验与媒体检查严格限定在传入的 `mod_root` 内，拒绝 `..` 路径逃逸，并对单次检查的文件数设上限。
- **日志白名单**：日志工具仅允许读取预先登记的 HOI4 日志文件名，杜绝任意文件读取。
- **工具未出现时**：先确认 `python` / `py -3` 已在 PATH 中、重新打开新对话，再运行 `python scripts/test-mcp-server.py` 定位问题。

## 可选进阶：独立桌面实机测试 MCP（`hoi4_desktop`）

为了守住 `hoi4_local` 绝对只读的底线，所有涉及窗口截图与键鼠操控的能力都被彻底拆分到了另一台**默认关闭、按需启用**的本地服务器 `mcp-server/hoi4_desktop_mcp.py`（`hoi4_desktop`）：

- 专为 **Google Antigravity、Cursor、Claude Code、Gemini CLI** 等没有内置桌面 Computer Use 的客户端设计；
- 纯 Python 3 标准库 + Windows 原生 Win32 API，零外部依赖、零联网；
- 进程白名单硬编码锁死为 `hoi4.exe`、`Paradox Launcher`、`dowser.exe` 与 `Steam`，无法触碰浏览器、聊天软件或 IDE；
- 同样完整遵守 `hoi4-content-builder/workflows/test-mod.md` 的用户授权、短测预算与配置还原规范。

配置方法、安全细节与离线自检（`python scripts/test-desktop-mcp-server.py`）详见 [可选本地桌面控制 MCP 配置指南](DESKTOP_MCP_SETUP.md)。

后续迭代方向包括当前 playset 解析、descriptor 加载顺序关系图，以及更细粒度的日志根因归因。
