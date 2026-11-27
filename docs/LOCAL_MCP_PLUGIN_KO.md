# HOI4 로컬 플러그인 및 읽기 전용 MCP 도우미 (`hoi4_local`)

[简体中文](LOCAL_MCP_PLUGIN.md) | [English](LOCAL_MCP_PLUGIN_EN.md) | [日本語](LOCAL_MCP_PLUGIN_JA.md) | [Русский](LOCAL_MCP_PLUGIN_RU.md) | 한국어

## 구조와 역할

이 플러그인은 **세 가지 에이전트 스킬**과 **읽기 전용 로컬 MCP 서버(`hoi4_local`)**를 하나의 패키지로 묶은 구성입니다.
- **스킬**은 개발·점검 방법론(기능 설계, 대상 버전 검증, 증거 기준, 수정 범위, 인계 절차)을 정합니다.
- **`hoi4_local` MCP**는 자주 쓰는 로컬 확인 작업을 구조화되고 경계가 분명한 읽기 전용 도구로 제공합니다.
- **Codex 플러그인 매니페스트**는 둘을 단일 컴포넌트로 묶어 한 번에 설치·갱신할 수 있게 합니다.

`hoi4_local`은 로컬 환경의 객관적인 사실을 빠르게 전달하는 역할에 집중합니다. 최종 문법과 동작 판단은 대상 게임 빌드의 바닐라 사용처, 활성 의존 모드, 실제 게임 관찰과 교차 확인해 내립니다. MCP를 쓰지 않는 환경에서도 저장소의 PowerShell·Python·`rg`·Git 스크립트로 전체 절차를 동일하게 진행할 수 있습니다.

## 여섯 가지 읽기 전용 도구

| 도구 | 기능 | 활용 팁 |
| --- | --- | --- |
| `detect_hoi4_environment` | 모드 작업공간, HOI4 설치 경로, 사용자 데이터, 로그, 창작마당 위치를 탐색 | 로컬 경로 전체를 파악합니다. 현재 켜 둔 모드 목록은 플레이세트나 `dlc_load.json`으로 함께 확인하세요 |
| `trace_hoi4_identifier` | 모드·바닐라·지정 의존 모드에서 ID, 플래그, 현지화 키, GFX 이름을 정확히 추적 | 텍스트 일치 결과를 반환합니다. 찾은 뒤에는 호출 코드가 실제로 소비하는지 이어서 확인합니다 |
| `validate_hoi4_changes` | 명시한 경로나 Git 변경 파일에 경량 PDX·현지화 정적 검사를 실행 | 변경 파일만 읽기 전용으로 검사합니다. 저장소 전체 감사는 Mod Doctor를 사용하세요 |
| `read_hoi4_logs` | `error.log`, `game.log` 등 등록된 HOI4 로그 끝부분을 제한 범위로 읽고 중복 행을 묶음 | 원본 로그는 절대 지우지 않습니다. 분석 전 타임스탬프가 최신 실행과 맞는지 확인하세요 |
| `inspect_hoi4_media` | DDS/PNG/JPEG/GIF 크기·포맷 메타데이터와 `ffprobe` 설치 시 오디오·비디오 스트림을 조회 | 객관적인 파일 규격을 보여 줍니다. 렌더링 요건은 해당 GUI/GFX 사용처 규칙에 맞춰 점검합니다 |
| `lookup_hoi4_console_commands` | 검증된 HOI4 1.20.0 콘솔 명령·조정 변수 458종을 이름·별칭·분류·의도로 검색(설치된 `documentation/console_commands_documentation.md` 자동 병합) | 정식 빌드 지원 여부, AI 동시 적용 주의, 흔한 실수(`eval_effect` vs `effect`)와 개발 빌드 전용 경고를 함께 제공합니다 |

여섯 도구 모두 **100% 읽기 전용**입니다. Steam이나 HOI4를 실행하지 않고, 플레이세트를 바꾸지 않으며, 모드 파일을 만들거나 고치거나 지우지 않고, 실행 중인 게임 프로세스도 건드리지 않습니다. 화면 캡처와 입력 제어가 필요한 실기 테스트에는 아래처럼 물리적으로 분리된 선택형 서버 `hoi4_desktop`을 사용합니다.

## 동작 방식

- **로컬 stdio 전송**: 호스트 클라이언트가 필요할 때 자식 프로세스를 띄워 표준 입출력으로 한 줄당 하나의 UTF-8 JSON-RPC 메시지를 주고받습니다. 프로세스 수명은 클라이언트가 관리하며 네트워크 포트를 열지 않습니다.
- **무의존·오프라인**: Python 3 표준 라이브러리만으로 동작하며 클라우드 HOI4 자료나 OpenAI API 키가 필요 없습니다. `PATH`에 `ffprobe`가 있으면 스트림 정보를 자동으로 덧붙이고, 없으면 외부에서 내려받지 않고 누락 사실만 알립니다.

## 설치 및 업데이트

저장소 루트 자체가 플러그인 소스이며 `.codex-plugin/plugin.json`이 단일 `skills/`와 `.mcp.json`을 가리킵니다. 개발자 자가 점검:

```powershell
python scripts/test-mcp-server.py
python <plugin-creator>/scripts/validate_plugin.py <repository-root>
```

Windows 사용자는 저장소 루트에서 아래 명령 한 줄로 설치와 갱신을 끝낼 수 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-plugin.ps1
```

스크립트는 현재 사용자의 로컬 앱 데이터 폴더에 전용 `hoi4-local-modding` marketplace를 구성하고 갱신 식별자를 붙여 Codex CLI에 자동 등록합니다. 설치 또는 갱신 뒤에는 **새 Codex 작업을 열어** 최신 스킬과 MCP 도구를 불러오세요. 공개 릴리스에는 플러그인 통합 ZIP과 함께 비플러그인 클라이언트용 개별 스킬 ZIP 세 개도 같이 제공합니다.

## 보안 가드와 문제 해결

- **깨끗한 stdio 채널**: stdout에는 한 줄에 하나의 UTF-8 JSON-RPC 메시지만 쓰고, 진단 로그는 stderr로 보냅니다.
- **유계 스캔**: 검색 대상은 화이트리스트 텍스트 확장자로 제한하고 `.git`, `node_modules`, `dist`를 건너뛰며 파일 크기와 결과 수에 상한을 둡니다.
- **작업공간 경계 유지**: 정적 검사와 미디어 검사는 전달받은 `mod_root` 안으로 제한해 `..` 경로 이탈을 차단합니다.
- **로그 화이트리스트**: `read_hoi4_logs`는 미리 등록된 HOI4 로그 파일명만 읽어 임의 파일 접근을 막습니다.
- **MCP 도구가 보이지 않을 때**: `python` 또는 `py -3`가 `PATH`에 있는지 확인하고, 새 대화를 연 뒤 `python scripts/test-mcp-server.py`로 점검하세요.

## 선택 확장: 실기 테스트 전용 데스크톱 MCP (`hoi4_desktop`)

`hoi4_local`을 언제나 순수 읽기 전용으로 지키기 위해 화면 캡처와 마우스·키보드 제어는 **기본 비활성화·필요 시 수동 활성화**하는 독립 서버 `mcp-server/hoi4_desktop_mcp.py`(`hoi4_desktop`)로 분리했습니다.

- **Google Antigravity, Cursor, Claude Code, Gemini CLI** 등 내장 Windows 데스크톱 Computer Use가 없는 클라이언트용
- 순수 Python 3 표준 라이브러리 + Windows Win32 API 기반, 외부 의존성 0, 네트워크 0
- 프로세스 화이트리스트를 `hoi4.exe`, `Paradox Launcher`, `dowser.exe`, `Steam`으로 하드코딩해 브라우저·메신저·IDE 접근 원천 차단
- `hoi4-content-builder/workflows/test-mod.md`의 사용자 허가, 단기 테스트 예산, 설정 복구 원칙을 그대로 준수

설정 예시, 보안 경계, 오프라인 자가 점검(`python scripts/test-desktop-mcp-server.py`)은 [데스크톱 MCP 설정 가이드](DESKTOP_MCP_SETUP_KO.md)를 참고하세요.

향후에는 활성 플레이세트 자동 해석, descriptor 로드 순서 그래프, 더 세밀한 로그 원인 분류 기능을 확장할 계획입니다.
