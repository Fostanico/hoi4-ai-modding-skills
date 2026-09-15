# HOI4 本地插件与 MCP 助手

## 架构与职责

本插件由三套 Agent Skills 和一个本地只读 MCP 服务器组成。Skills 定义 HOI4 MOD
开发、审查、证据分级、版本核验、修改授权和验证流程；MCP 服务器将常用的本地取证
操作暴露为有界、结构化的工具接口。Codex Plugin 清单负责将二者作为单一组件发现和
安装。

MCP 工具只负责收集本地证据，不构成新的语法或运行时权威。工具输出仍须按照 Skills
规定的来源层级，与目标版本原版消费者、实际依赖和运行时证据交叉核验。MCP 不可用
时，PowerShell、Python、`rg`、Git 及仓库内置脚本仍是完整的备用执行路径。

## 工具接口

| 工具 | 用途 | 限制 |
| --- | --- | --- |
| `detect_hoi4_environment` | 查找 MOD 工作区、HOI4 安装、用户数据、日志和 Workshop | 不判断当前 playset 一定启用了什么 |
| `trace_hoi4_identifier` | 在 MOD、原版和指定依赖中追踪 ID、flag、本地化键、GFX 名称 | 精确文本搜索，不把命中自动等同为有效消费者 |
| `validate_hoi4_changes` | 对显式路径或 Git 变更运行轻量 PDX/本地化校验 | 不运行全量 Mod Doctor，不修改文件 |
| `read_hoi4_logs` | 有界读取 `error.log`、`game.log` 等日志尾部并合并重复行 | 不清空日志；旧时间戳不等于最新实机结果 |
| `inspect_hoi4_media` | 查看 DDS/PNG/JPEG/GIF 元数据及 ffprobe 音视频流 | 元数据不证明 HOI4 消费者一定支持该格式 |

五个工具全部只读。它们不会启动 Steam 或 HOI4，不会切换 playset，不会删除、
覆盖或创建 MOD 文件，也不会结束游戏进程。未来若加入写入或实机测试能力，应使用
独立工具接口、显式声明更高风险等级，并保留相应的用户授权边界。

## 传输与运行模型

MCP 服务器使用本地 stdio 传输。Codex 按需启动子进程，并通过标准输入/输出交换
MCP JSON-RPC 消息。该实现不需要公网服务、OpenAI API Key、端口映射或云端 HOI4
文件库；服务进程由客户端管理生命周期，不监听网络端口。

服务器只依赖 Python 3 标准库。媒体工具如果在 PATH 找到 `ffprobe`，会额外读取
音视频流信息；没有 `ffprobe` 时会明确报告缺失，而不是自动下载软件。

## 安装与刷新

仓库根目录本身就是插件源，`.codex-plugin/plugin.json` 引用唯一一份 `skills/`
和 `.mcp.json`。开发者先运行：

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

Windows 用户可在仓库根目录运行以下命令安装或刷新：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

脚本在当前用户的本地应用数据目录建立独立的 `hoi4-local-modding` marketplace，
为开发版本添加 cachebuster，并通过 Codex CLI 完成安装，无需手动维护 marketplace
JSON。安装或更新后应新建 Codex 任务，使新会话重新加载 Skills 和 MCP 工具。发布
包应包含完整插件 ZIP，同时保留三个独立 Skill ZIP，以支持不具备插件能力的客户端。

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

后续版本可增加当前 playset 解析、descriptor/load-order 关系图和更细粒度的日志
归因。写入型脚手架与自动化运行时测试应作为独立阶段设计，并强制采用变更预览、
目标路径限制、可恢复修改、结果验证和显式授权，不与现有只读接口混用。
