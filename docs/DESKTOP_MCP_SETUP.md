# 可选本地桌面实机测试 MCP（`hoi4_desktop`）配置指南

`hoi4_desktop`（`mcp-server/hoi4_desktop_mcp.py`）是一台面向 **非 Codex 客户端**（如 **Google Antigravity、Cursor、Claude Code、Gemini CLI、Windsurf、Cline** 等无内置 Windows 桌面 Computer Use 的 AI 客户端）打造的**通用标准 MCP 服务器**，默认不启用，仅在你希望 AI 协助执行 [test-mod.md](../skills/hoi4-content-builder/workflows/test-mod.md) 实机验收时按需开启。

它与只读取证服务器 `hoi4_local`（`mcp-server/hoi4_mcp.py`）**完全物理分离**：日常开发、代码审查与静态检查始终只使用只读的 `hoi4_local`；实机测试结束后随时一键关闭 `hoi4_desktop` 即可。

## 设计亮点与安全防线

- **标准通用、零依赖、零联网**：基于标准 MCP stdio JSON-RPC 2.0 协议，纯 Python 3 标准库 + Windows 原生 Win32 API（`user32`/`gdi32`/`kernel32`/`shell32`）与纯 Python PNG 编码，免 `pip install`，不监听网络端口。
- **硬编码进程白名单**：只允许发现、截取和操作以下 5 个 HOI4 相关进程窗口，浏览器、聊天软件、IDE 等其他桌面应用一概不可见、不可点：
  - `hoi4.exe`
  - `paradox launcher.exe`、`dowser.exe`
  - `steam.exe`、`steamwebhelper.exe`
- **精准客户区截屏与越界拦截**：只截取已核验白名单窗口的客户区（优先 `PrintWindow(PW_RENDERFULLCONTENT)`，DX11 黑帧时仅在确认目标窗口位于前台后按客户区精准裁剪 `BitBlt`）；所有点击、拖拽与滚轮均走窗口相对坐标，越界直接拒绝。
- **前台实时核验与一键熔断**：发送输入前再次校验前台窗口归属，禁用 `Alt+Tab` / `Alt+F4`；随时将鼠标甩到屏幕左上角（`x <= 4, y <= 4`）即可触发紧急停止。
- **专为 HOI4 实机场景打磨**：
  - 完整支持 Per-Monitor V2 DPI 感知与多屏虚拟桌面坐标；
  - 快捷键使用 DirectX 硬件扫描码（稳定触发 `` ` `` 控制台、`Space`、`Esc`）；
  - 文本输入使用 `KEYEVENTF_UNICODE` 直接注入 UTF-16 码元，彻底绕开中/日/韩输入法（如微软拼音），不再出现 `cp 100` 被打成汉字或空格被吞的情况；
  - 隔离桌面自检：`list_hoi4_windows` 返回当前 Win32 桌面名（`desktop_name`），若宿主把 MCP 子进程放进非 `Default` 隔离桌面会第一时间告警；
  - Steam 启动硬编码 AppID `394360`，并强制校验 `confirm_user_authorized: true`，同时遵守 `test-mod.md` 的授权与配置还原纪律。

## 运行前提

1. **Windows 10 / 11 + Python 3**（`py -3` 或 `python` 在 PATH 中）。
2. **推荐无边框全屏（Borderless）或窗口化（Windowed）**：部分显卡驱动在独占全屏下会拦截 GDI/PrintWindow 截屏。
3. **权限一致**：以普通用户权限运行 `hoi4.exe`（不要单独勾选管理员运行），确保同权限的客户端能正常发送键鼠输入。

## 暴露的工具（10 项）

| 工具 | 性质 | 用途 |
| --- | --- | --- |
| `list_hoi4_windows` | 只读 | 列出当前可见的白名单窗口（句柄、进程名、标题、客户区尺寸、前台状态与桌面名） |
| `capture_hoi4_window` | 只读 | 仅截取指定白名单窗口客户区为 PNG，返回坐标信息、临时文件路径与内联 MCP 图块 |
| `focus_hoi4_window` | 交互 | 还原最小化并将指定白名单窗口切至前台（支持后台焦点交接） |
| `click_hoi4_window` | 交互 | 按归一化（`0.0–1.0`）、客户区像素或截图缩放像素在窗口内点击，支持操作后即刻截屏 |
| `drag_hoi4_window` | 交互 | 在窗口内平滑拖拽（地图平移、滚动条、可拖动窗口） |
| `scroll_hoi4_window` | 交互 | 在指定坐标滚动滚轮（地图缩放、决议/国策列表滚动） |
| `send_hoi4_keys` | 交互 | 发送 DirectX 硬件扫描码按键或组合键（屏蔽 `Alt+Tab` / `Alt+F4`） |
| `type_hoi4_text` | 交互 | 以输入法免疫的 Unicode 直注方式向目标窗口输入短文本（上限 500 字符） |
| `run_hoi4_console_command` | 交互 | **仅限 `hoi4.exe`**：自动开启控制台、输入单行指令、回车，并可选关闭控制台与截屏 |
| `launch_hoi4_steam` | 交互 | 经用户明确授权后打开 `steam://rungameid/394360`（需传 `confirm_user_authorized: true`） |

## 客户端接入示例

将 `<REPO_ROOT>` 替换为本仓库（或插件）的本地绝对路径。建议平时关闭该服务器，需要实机验收时再开启。

### 1. Google Antigravity（推荐做成独立可开关插件）

在 `~/.gemini/config/plugins/hoi4-desktop-control/` 中放置 `plugin.json`、`mcp_config.json` 与 `mcp-server/hoi4_desktop_mcp.py`，并在 `mcp_config.json` 中写入：

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

配置完成后即可在 Antigravity 的 **Plugins Manager** 里一键开关，完全不影响只读的 `hoi4_local` 和三套 Skills。

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

也可以直接套用仓库内的模板 [mcp-server/hoi4_desktop.mcp.example.json](../mcp-server/hoi4_desktop.mcp.example.json)。

### 3. Codex

Codex 桌面版已内置原生 Computer Use，默认插件清单 `.mcp.json` 仅注册只读的 `hoi4_local`，无需重复挂载 `hoi4_desktop`。

## 离线自检（零桌面副作用）

在仓库根目录执行：

```powershell
python scripts/test-desktop-mcp-server.py
```

测试脚本会完整校验进程白名单拦截、坐标越界拒绝、纯 Python PNG 编解码往返、空值参数容错、JSON-RPC 握手、10 项工具清单以及未授权 `launch_hoi4_steam` 拒绝，全程不启动 Steam、不触碰桌面窗口。
