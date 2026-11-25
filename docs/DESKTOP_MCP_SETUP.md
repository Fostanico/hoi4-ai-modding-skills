# 可选本地桌面控制 MCP（`hoi4_desktop`）配置指南

`hoi4_desktop`（`mcp-server/hoi4_desktop_mcp.py`）是面向 **非 Codex 客户端**（如 **Google Antigravity、Cursor、Claude Code、Gemini CLI、Windsurf / Cline** 等无内置 Windows 桌面 Computer Use 的 AI 客户端）提供的**可选、默认不自动启用**的本地 HOI4 实机测试 MCP 服务器。

它与只读取证服务器 `hoi4_local`（`mcp-server/hoi4_mcp.py`）**完全物理分离**：只读开发与审查始终只使用 `hoi4_local`，只有当用户需要 AI 协助执行 [test-mod.md](../skills/hoi4-content-builder/workflows/test-mod.md) 实机验证时，才手动启用 `hoi4_desktop`。

## 核心特点与安全边界

- **零第三方依赖、零联网**：仅使用 Python 3 标准库 + Windows 原生 Win32 API（`user32`/`gdi32`/`kernel32`/`shell32`）与纯 Python PNG 编码，不需 `pip install` 任何包，不监听网络端口。
- **硬编码进程白名单**：只允许列举、截取和操作以下 5 个 HOI4 相关进程窗口，**拒绝访问浏览器、聊天软件、IDE 或其他桌面窗口**：
  - `hoi4.exe`
  - `paradox launcher.exe`、`dowser.exe`
  - `steam.exe`、`steamwebhelper.exe`
- **不截全屏、不越界点击**：只截取已核验白名单窗口的客户区（优先 `PrintWindow(PW_RENDERFULLCONTENT)`，DX11 黑帧时仅在确认目标窗口已置顶后裁剪客户区 `BitBlt`）；所有点击/拖拽/滚轮均使用窗口相对坐标，越界直接拒绝。
- **前台校验与紧急熔断**：发送键鼠前实时核验前台窗口归属；禁止 `Alt+Tab` / `Alt+F4`；鼠标移到屏幕左上角（`x <= 4, y <= 4`）立即触发紧急中止。
- **专为 HOI4 优化**：支持 Per-Monitor V2 DPI 感知、多屏虚拟桌面坐标、DirectX 硬件扫描码（可稳定按出 `` ` `` 控制台、`Space`、`Esc`）、`KEYEVENTF_UNICODE` 文本直注（避免中文/日文/韩文输入法劫持 `pp 500` / `cp 100` 等控制台指令），并提供仅限 `hoi4.exe` 的单步控制台指令工具 `run_hoi4_console_command`。
- **隔离桌面自检**：`list_hoi4_windows` 返回当前 Win32 桌面名（`desktop_name`），若客户端将子进程隔离在非 `Default` 桌面会直接告警，不返回静默空列表。
- **Steam 启动显式确认**：`launch_hoi4_steam` 仅硬编码 `steam://rungameid/394360`，必须传入 `confirm_user_authorized: true`，且 AI 仍须遵守 `test-mod.md` 中的用户授权与播放集还原规则。

## 运行前提

1. **Windows 10 / 11 + Python 3**（`py -3` 或 `python` 在 `PATH` 中）。
2. **HOI4 显示模式建议设为「无边框全屏（Borderless）」或「窗口化（Windowed）」**：独占全屏下部分显卡驱动会拦截 GDI/PrintWindow 截屏。
3. **权限一致**：不要单独以管理员身份运行 `hoi4.exe`，否则普通权限下的 AI 客户端无法通过 `SendInput` 注入键鼠。

## 暴露的工具（10 项）

| 工具 | 性质 | 用途 |
| --- | --- | --- |
| `list_hoi4_windows` | 只读 | 列出当前可见的白名单窗口（句柄、进程名、标题、客户区宽高、前台状态） |
| `capture_hoi4_window` | 只读 | 仅截取指定白名单窗口客户区为 PNG，返回坐标缩放信息、临时文件路径与内联 MCP 图片 |
| `focus_hoi4_window` | 交互 | 还原最小化并将指定白名单窗口切至前台 |
| `click_hoi4_window` | 交互 | 按归一化（`0.0–1.0`）、客户区像素或截图缩放像素在窗口内点击，可选操作后截屏 |
| `drag_hoi4_window` | 交互 | 在窗口内平滑拖拽（地图平移、滑条、可拖动超事件窗） |
| `scroll_hoi4_window` | 交互 | 在窗口内指定位置滚动滚轮（地图缩放、决议/国策列表滚动） |
| `send_hoi4_keys` | 交互 | 以 DirectX 硬件扫描码发送按键或组合键（屏蔽 `Alt+Tab`/`Alt+F4`） |
| `type_hoi4_text` | 交互 | 向白名单窗口输入短文本（上限 500 字符） |
| `run_hoi4_console_command` | 交互 | **仅限 `hoi4.exe`**：自动开控制台、输入单行指令、回车、可选关闭控制台并截屏 |
| `launch_hoi4_steam` | 交互 | 经用户明确授权后打开 `steam://rungameid/394360`（需 `confirm_user_authorized: true`） |

## 客户端配置示例

将下方 `<REPO_ROOT>` 替换为本仓库（或插件）的本地绝对路径。建议平时关闭该服务器，仅在需要实机验收时启用。

### 1. Google Antigravity（推荐做成独立可开关插件）

在 `~/.gemini/config/plugins/hoi4-desktop-control/` 中放置 `plugin.json`、`mcp_config.json` 与 `mcp-server/hoi4_desktop_mcp.py`，并在 `mcp_config.json` 写入：

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "py",
      "args": [
        "-3",
        "-u",
        "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control\\mcp-server\\hoi4_desktop_mcp.py"
      ],
      "cwd": "C:\\Users\\<YOUR_USER>\\.gemini\\config\\plugins\\hoi4-desktop-control"
    }
  }
}
```

配置完成后可在 Antigravity 的 **Plugins Manager** 中随时一键开启或停用，不影响只读的 `hoi4_local` 与三套 Skills。

### 2. Cursor / Claude Code / Gemini CLI / Windsurf / Cline

在对应客户端的 MCP 配置文件（如 `.cursor/mcp.json`、`.mcp.json`、`~/.claude.json` 或 `~/.gemini/settings.json`）的 `mcpServers` 中加入：

```json
{
  "mcpServers": {
    "hoi4_desktop": {
      "command": "cmd.exe",
      "args": [
        "/d",
        "/s",
        "/c",
        "call",
        "<REPO_ROOT>\\mcp-server\\launch_desktop.cmd"
      ]
    }
  }
}
```

也可以直接参考仓库模板 [mcp-server/hoi4_desktop.mcp.example.json](../mcp-server/hoi4_desktop.mcp.example.json)。

### 3. Codex

Codex 桌面版已内置原生 Computer Use，默认插件清单 `.mcp.json` **故意保持纯只读**（仅注册 `hoi4_local`），无需重复启用 `hoi4_desktop`。

## 离线自检（不启动游戏、不操作桌面）

在仓库根目录运行：

```powershell
python scripts/test-desktop-mcp-server.py
```

该测试验证进程白名单拒绝、坐标越界拦截、纯 Python PNG 编码往返、JSON-RPC 握手、10 项工具清单以及未授权 `launch_hoi4_steam` 拒绝，不会启动 Steam 或修改桌面状态。
