# 선택형 로컬 데스크톱 실기 테스트 MCP (`hoi4_desktop`) 설정 가이드

[简体中文](DESKTOP_MCP_SETUP.md) | [English](DESKTOP_MCP_SETUP_EN.md) | [日本語](DESKTOP_MCP_SETUP_JA.md) | [Русский](DESKTOP_MCP_SETUP_RU.md) | 한국어

`hoi4_desktop`(`mcp-server/hoi4_desktop_mcp.py`)은 내장 Windows 데스크톱 Computer Use가 없는 **비 Codex 클라이언트**(**Google Antigravity, Cursor, Claude Code, Gemini CLI, Windsurf, Cline** 등)를 위해 만든 **범용 표준 MCP 서버**입니다. 기본값은 비활성화이며, [test-mod.md](../skills/hoi4-content-builder/workflows/test-mod.md) 절차에 따라 AI와 함께 실기 검증을 진행할 때만 켜서 사용합니다.

읽기 전용 취증 서버 `hoi4_local`(`mcp-server/hoi4_mcp.py`)과는 **완전히 물리적으로 분리**되어 있습니다. 일상적인 개발·리뷰·정적 검사는 `hoi4_local`만 쓰고, 실기 테스트가 끝나면 `hoi4_desktop`을 바로 꺼 두면 깔끔합니다.

## 설계 강점과 보안 가드

- **표준 호환·무의존·오프라인**: 표준 MCP stdio JSON-RPC 2.0을 따르며 Python 3 표준 라이브러리, Windows Win32 API(`user32`/`gdi32`/`kernel32`/`shell32`), 순수 Python PNG 인코더만으로 동작합니다. `pip install`도, 네트워크 포트도 필요 없습니다.
- **하드코딩된 프로세스 화이트리스트**: 아래 HOI4 관련 5개 프로세스 창만 조회·캡처·조작할 수 있으며 브라우저·메신저·IDE 등 다른 앱 창은 보이지도, 클릭되지도 않습니다.
  - `hoi4.exe`
  - `paradox launcher.exe`, `dowser.exe`
  - `steam.exe`, `steamwebhelper.exe`
- **클라이언트 영역 한정 캡처 및 좌표 경계 차단**: 화이트리스트가 확인된 창의 클라이언트 영역만 캡처합니다(`PrintWindow(PW_RENDERFULLCONTENT)` 우선, DX11 검은 프레임일 때만 전면 확인 후 클라이언트 영역에 맞춘 `BitBlt`로 전환). 클릭·드래그·스크롤은 창 상대 좌표를 쓰며 영역 밖 좌표는 즉시 거부합니다.
- **실시간 전면 검증 및 긴급 중단**: 입력 전마다 전면 창 소유권을 다시 확인하고 `Alt+Tab` / `Alt+F4`를 차단합니다. 마우스를 화면 왼쪽 위 모서리(`x <= 4, y <= 4`)로 옮기면 즉시 입력이 중단됩니다.
- **HOI4 실기 테스트에 맞춘 세부 튜닝**:
  - Per-Monitor V2 DPI 인식 및 멀티 모니터 가상 데스크톱 좌표 매핑
  - DirectX 하드웨어 스캔코드 단축키 전송(`` ` `` 콘솔, `Space`, `Esc`)
  - `KEYEVENTF_UNICODE` UTF-16 직접 주입으로 한국어·중국어·일본어 IME 간섭 완전 우회(`cp 100`, `pp 500` 같은 콘솔 명령이 한글 조합으로 깨지거나 공백이 사라지지 않음)
  - 격리 데스크톱 자가 진단: `list_hoi4_windows`가 `desktop_name`을 반환해 호스트가 `Default`가 아닌 격리 데스크톱에서 실행할 경우 즉시 경고
  - Steam 실행 URI는 `steam://rungameid/394360` 고정 및 `confirm_user_authorized: true` 필수, `test-mod.md`의 승인·설정 복구 규칙 준수

## 실행 전제

1. **Windows 10 / 11 + Python 3**(`py -3` 또는 `python`이 `PATH`에 등록됨).
2. **테두리 없는 창 모드(Borderless) 또는 창 모드(Windowed) 권장**: 단독 전체 화면에서는 일부 그래픽 드라이버가 GDI/`PrintWindow` 캡처를 막습니다.
3. **권한 일치**: `hoi4.exe`를 일반 사용자 권한으로 실행하세요(관리자 권한으로 따로 실행하면 일반 권한 클라이언트의 `SendInput`이 전달되지 않습니다).

## 제공 도구 (11종)

| 도구 | 성격 | 용도 |
| --- | --- | --- |
| `list_hoi4_windows` | 읽기 전용 | 표시 중인 화이트리스트 창 목록(핸들, 프로세스명, 제목, 클라이언트 크기, 전면 여부, 데스크톱명) |
| `capture_hoi4_window` | 읽기 전용 | 대상 창 클라이언트 영역만 PNG 캡처 후 좌표 정보·임시 파일 경로·인라인 MCP 이미지 반환 |
| `focus_hoi4_window` | 상호작용 | 최소화 복원 및 전면 전환(백그라운드 포커스 인계 지원) |
| `click_hoi4_window` | 상호작용 | 정규화(`0.0–1.0`), 클라이언트 px, 이미지 px 좌표로 창 내부 클릭(클릭 직후 캡처 옵션 포함) |
| `drag_hoi4_window` | 상호작용 | 창 내부 부드러운 드래그(지도 이동, 스크롤바, 이동식 패널) |
| `scroll_hoi4_window` | 상호작용 | 지정 위치에서 마우스 휠 스크롤(지도 확대/축소, 결정·국가중점 목록 스크롤) |
| `send_hoi4_keys` | 상호작용 | DirectX 하드웨어 스캔코드 키·조합키 전송(`Alt+Tab` / `Alt+F4` 차단) |
| `type_hoi4_text` | 상호작용 | IME 간섭 없는 Unicode 직접 주입으로 짧은 텍스트 입력(최대 500자) |
| `lookup_hoi4_console_commands` | 읽기 전용 | 콘솔 실행 전 HOI4 1.20.0 명령·변수 458종 실시간 검색(문법, 예시, AI 영향, 정식 빌드 지원 여부) |
| `run_hoi4_console_command` | 상호작용 | **`hoi4.exe` 전용**: 콘솔(`` ` ``)을 열고 한 줄 명령 실행, 선택적으로 닫기 및 캡처(문법 오용 경고 포함) |
| `launch_hoi4_steam` | 상호작용 | 사용자 명시 승인 후 `steam://rungameid/394360` 실행(`confirm_user_authorized: true` 필수) |

## 클라이언트 연결 예시

`<REPO_ROOT>`를 이 저장소(또는 플러그인)의 로컬 절대 경로로 바꾸세요. 평소에는 꺼 두고 실기 검증이 필요할 때만 켜는 방식을 권장합니다.

### 1. Google Antigravity (권장: 독립 토글 플러그인)

`~/.gemini/config/plugins/hoi4-desktop-control/` 아래에 `plugin.json`, `mcp_config.json`과 `mcp-server/`의 `hoi4_desktop_mcp.py`, `hoi4_console_catalog.py`, `hoi4_console_commands.json`을 배치하고 `mcp_config.json`에 아래 내용을 적습니다.

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

설정해 두면 Antigravity의 **Plugins Manager**에서 원클릭으로 켜고 끌 수 있으며, 읽기 전용 `hoi4_local`과 세 스킬에는 영향을 주지 않습니다.

### 2. Cursor / Claude Code / Gemini CLI / Windsurf / Cline

각 클라이언트의 MCP 설정 파일(`.cursor/mcp.json`, `.mcp.json`, `~/.claude.json`, `~/.gemini/settings.json` 등)의 `mcpServers`에 추가합니다.

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

저장소 템플릿 [mcp-server/hoi4_desktop.mcp.example.json](../mcp-server/hoi4_desktop.mcp.example.json)을 그대로 참고해도 됩니다.

### 3. Codex

Codex 데스크톱 앱은 네이티브 Computer Use를 기본 제공하므로 기본 `.mcp.json`에는 읽기 전용 `hoi4_local`만 등록합니다.

## 오프라인 자가 점검 (데스크톱 부작용 없음)

저장소 루트에서 실행합니다.

```powershell
python scripts/test-desktop-mcp-server.py
```

프로세스 화이트리스트 차단, 범위 밖 좌표 거부, 순수 Python PNG 인코딩·디코딩 왕복, `null` 인자 폴백, 콘솔 명령 검색 및 문법 경고, JSON-RPC 핸드셰이크, 11개 도구 스키마, 미승인 `launch_hoi4_steam` 거부를 한 번에 검증하며 Steam을 띄우거나 데스크톱 창을 건드리지 않습니다.
