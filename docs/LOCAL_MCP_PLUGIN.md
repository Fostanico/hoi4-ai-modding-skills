# HOI4 本地插件与 MCP 助手

## 用一句话理解

原来的三个 Skills 是“实验教材”，新增的 MCP 是“本机检测仪器”，Codex Plugin
把二者装进同一个工具箱。它不把游戏文件上传到一台假装拥有 HOI4 的云服务器，
而是在用户自己的电脑上读取当前安装、MOD、日志和媒体元数据，再把有界结果交给
Codex 判断。

MCP 工具不代替 Skills。Skills 仍决定证据顺序、改动边界、验证分档和运行时测试
条件；MCP 只把重复的本地取证步骤变成稳定、结构化的调用。MCP 不可用时，Skills
中的 PowerShell、Python、`rg` 和 Git 工作流仍然有效。

## 第一版提供什么

| 工具 | 用途 | 首版边界 |
| --- | --- | --- |
| `detect_hoi4_environment` | 查找 MOD 工作区、HOI4 安装、用户数据、日志和 Workshop | 不判断当前 playset 一定启用了什么 |
| `trace_hoi4_identifier` | 在 MOD、原版和指定依赖中追踪 ID、flag、本地化键、GFX 名称 | 精确文本搜索，不把命中自动等同为有效消费者 |
| `validate_hoi4_changes` | 对显式路径或 Git 变更运行轻量 PDX/本地化校验 | 不运行全量 Mod Doctor，不修改文件 |
| `read_hoi4_logs` | 有界读取 `error.log`、`game.log` 等日志尾部并合并重复行 | 不清空日志；旧时间戳不等于最新实机结果 |
| `inspect_hoi4_media` | 查看 DDS/PNG/JPEG/GIF 元数据及 ffprobe 音视频流 | 元数据不证明 HOI4 消费者一定支持该格式 |

五个工具全部只读。它们不会启动 Steam 或 HOI4，不会切换 playset，不会删除、
覆盖或创建 MOD 文件，也不会结束游戏进程。今后即使加入写入或实机测试能力，也
应该使用不同工具名并保留明确授权边界，不能悄悄扩大本工具的权限。

## 为什么使用本地 stdio MCP

Codex 在需要工具时启动本机子进程，通过标准输入/输出交换 MCP JSON-RPC 消息。
因此不需要公网服务器、OpenAI API Key、端口映射或云端 HOI4 文件库。服务进程与
当前 Codex 会话同寿命，退出后不会常驻监听网络端口。

服务器只依赖 Python 3 标准库。媒体工具如果在 PATH 找到 `ffprobe`，会额外读取
音视频流信息；没有 `ffprobe` 时会明确报告缺失，而不是自动下载软件。

## 安装与刷新

仓库根目录本身就是插件源，`.codex-plugin/plugin.json` 引用唯一一份 `skills/`
和 `.mcp.json`。开发者先运行：

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

普通用户在仓库根目录运行一条命令即可安装或刷新：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

脚本在当前用户的本地应用数据目录建立独立的 `hoi4-local-modding` marketplace，
为版本添加一次 cachebuster，并通过 Codex CLI 安装；用户不需要手改 JSON。安装或
更新后新建 Codex 任务，让新会话重新加载 Skills 和 MCP 工具。发布包应增加
一个完整插件 ZIP，同时保留原有三个单独 Skill ZIP，方便不支持插件的客户端。

## 安全与排错

- MCP 的标准输出只允许一行一个 UTF-8 JSON-RPC 消息；调试信息必须写入标准错误。
- 搜索只读取有限的文本扩展名，跳过 `.git`、`node_modules`、`dist` 等目录，并限制
  单文件大小和返回条数。
- 校验路径必须保持在传入的 `mod_root` 内，不能用 `..` 越出工作区。
- 日志工具只能选择预先登记的 HOI4 日志名，不能借此读取任意文件。
- 媒体工具只接受 `mod_root` 内的媒体文件，并对文件数量设置上限。
- 若插件能列出但 MCP 工具没有出现，先确认 Python 3 在 PATH、重新打开任务，再运行
  `python scripts/test-mcp-server.py`；不要因此直接修改 MOD 或启动游戏。

## 后续阶段

第二阶段可以加入当前 playset 解析、descriptor/load-order 图和更细的日志归因；第三
阶段再考虑需要写入的脚手架和经用户明确同意的最小实机测试。写工具必须采用预览、
限定目标、可恢复改动和变更后验证，不能沿用首版只读工具名冒充同一种风险级别。
