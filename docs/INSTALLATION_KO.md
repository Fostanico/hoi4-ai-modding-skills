# HOI4 AI Modding Skills 설치 및 공유 안내

[简体中文](INSTALLATION.md) | [English](INSTALLATION_EN.md) | [日本語](INSTALLATION_JA.md) | [Русский](INSTALLATION_RU.md) | 한국어

## 패키지 구성

이 툴킷은 **기존 *Hearts of Iron IV* 모드의 유지보수·진단·리팩터링·지속적 고도화를 중심**으로 삼으면서, **일상 언어로 새 기능이나 완성된 모드를 처음부터 제작하는 전체 워크플로**도 함께 제공하는 3종 에이전트 스킬 세트입니다.

- **`hoi4-review-debug`**: 기존 모드의 로그 분석, 파일 횡단 감사, 버전 이행, 성능 최적화, 사용자 동의를 거친 실기 검증을 맡습니다.
- **`hoi4-pdx-modding`**: PDX 문법, 디렉터리 규칙, 대상 게임 빌드 검증, 정적 검사의 기준을 지킵니다.
- **`hoi4-content-builder`**: 자연어 게임플레이 구상을 스크립트·에셋·UI·다국어 현지화까지 연결된 새 기능이나 완성된 모드로 구현합니다.

**세 스킬은 반드시 한 세트로 함께 설치하세요.** 규칙, 템플릿, 인계 절차를 서로 참조하기 때문에 세 개가 모두 있어야 ‘설계 → 구현 → 검증’ 흐름이 매끄럽게 이어집니다. PDX 스크립트를 먼저 쓸 필요 없이 원하는 규칙과 화면, 에셋을 바로 설명하면 됩니다. 특정 모드 고유의 변수·플래그·의존성·인코딩 규칙은 해당 모드의 기술 문서에 보관하고, 공용 스킬은 가볍고 범용적으로 유지합니다.

## 배포 및 릴리스 원칙

1. **소스 코드와 버전이 붙은 Release로 배포하세요.** 출처와 버전을 알 수 없는 압축 파일만 전달하지 않습니다.
2. **세 스킬이 모두 담긴 통합 패키지를 기본 다운로드로 제공하세요.** 릴리스 노트에 버전, 기준 커밋, 파일 크기를 적고(체크섬은 배포 채널 요구나 전송 손상 확인이 필요할 때 추가), 한 번에 하나씩만 업로드할 수 있는 플랫폼이라면 같은 릴리스의 개별 ZIP 세 개를 함께 올리고 전부 설치하도록 안내합니다.
3. **메타데이터와 폴더 구조를 유지하세요.** `LICENSE`, `ATTRIBUTION.md`, 각 스킬의 전체 하위 디렉터리를 그대로 포함합니다.
4. **저작권 경계를 지키세요.** Paradox 바닐라 파일, 창작마당 튜토리얼, 타 모드 에셋, 개인 로컬 경로는 배포 패키지에 넣지 않습니다. 바닐라 및 제3자 파일은 로컬 검증에만 사용합니다.
5. **대형 패치에 맞춰 갱신하세요.** HOI4 대형 버전이 올라갈 때마다 `references/template-catalog.md`의 바닐라 사용처를 다시 확인하고 검증한 게임 빌드를 릴리스 노트에 기록합니다.

## 클라이언트별 설치 방법

### ChatGPT

Personal Skills를 지원하는 계정에서 프로필 → **Skills** → **Create** → **Upload from your computer**로 들어가 같은 Release의 스킬 ZIP 세 개를 차례로 올리고 모두 켜 두세요. 설치 후 Skills 화면에서 워크스페이스 공유나 링크 생성이 가능합니다. 지원 플랜과 관리자 설정은 [OpenAI Skills 공식 안내](https://help.openai.com/en/articles/20001066-skills-in-chatgpt)를 따르며, 외부 패키지는 사용 전에 출처와 스크립트를 직접 검토하는 것이 안전합니다.

### Codex

- **사용자 단위 설치**: 세 스킬 폴더를 `$CODEX_HOME/skills/`에 복사합니다.
- **프로젝트 단위 설치**: 대상 모드의 `.agents/skills/`에 복사해 Git과 함께 관리하며 아래 구조를 유지합니다.

```text
.agents/skills/
  hoi4-content-builder/SKILL.md
  hoi4-pdx-modding/SKILL.md
  hoi4-review-debug/SKILL.md
```

새로고침하거나 새 작업을 연 뒤 자연어로 HOI4 모드 작업을 요청하면 됩니다. 특정 프로젝트에 오래 적용할 규칙과 문서 진입점은 프로젝트 루트의 `AGENTS.md`에 정리합니다.

#### 선택 사항: 읽기 전용 로컬 도구가 포함된 Codex 플러그인 설치

저장소 루트 자체가 세 스킬과 읽기 전용 로컬 MCP `hoi4_local`을 함께 담은 완전한 Codex 플러그인 소스입니다. 로컬 HOI4 설치 탐색, 식별자 추적, Git 변경 검증, 로그 읽기, 미디어 메타데이터 확인이 필요할 때 유용합니다. 설치 명령과 보안 경계는 [로컬 플러그인 및 MCP 도우미](LOCAL_MCP_PLUGIN_KO.md)를 참고하세요.

> **안내**: 로컬 플러그인을 설치하거나 갱신한 뒤에는 **새 Codex 작업을 여세요.** 이미 열려 있는 작업은 시작 시점의 도구 목록을 고정하므로, 바뀐 스킬과 MCP 도구는 새 작업에서 불러와집니다.

### Cursor

Cursor Agent는 프로젝트 경로 `.agents/skills/<skill-name>/`, `.cursor/skills/<skill-name>/`와 사용자 경로 `~/.agents/skills/<skill-name>/`, `~/.cursor/skills/<skill-name>/`를 자동 탐지합니다. 같은 Release의 세 폴더를 원하는 위치에 복사하세요(프로젝트 경로는 모드 저장소와 함께 관리하기 좋고, 사용자 경로는 여러 모드에서 공유하기 좋습니다).

Agent를 다시 열거나 새로고침하면 요청에 따라 자동 매칭되며, 채팅에서 `/`를 입력해 스킬 이름으로 직접 호출할 수도 있습니다. 현재 선택한 어떤 모델에도 함께 전달되며, Cloud Agents에서 개인 `~/.cursor/skills/`를 쓰려면 Cursor 설정에서 Skills 동기화를 켜세요. 로컬 취증이나 허가 기반 실기 테스트를 붙이려면 `.cursor/mcp.json`에 `hoi4_local`이나 `hoi4_desktop`을 등록하면 됩니다. 최신 경로와 원격 규칙은 [Cursor Agent Skills 공식 문서](https://cursor.com/docs/skills)를 참고하세요.

### Claude Code / claude.ai

- **Claude Code**: `~/.claude/skills/<skill-name>/`(사용자 단위) 또는 `.claude/skills/<skill-name>/`(프로젝트 단위)에 세 폴더를 넣으세요. `description` 기반 자동 로드와 명시적 호출을 모두 지원합니다. 참고: [Claude Code Skills 문서](https://code.claude.com/docs/en/slash-commands).
- **claude.ai**: **Settings → Features**에서 커스텀 스킬 ZIP을 업로드할 수 있으며, 지원 요금제와 실행 환경 규칙은 [Anthropic Agent Skills 안내](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)를 따릅니다.

### Gemini CLI / Google Antigravity

- **Gemini CLI**: 사용자 경로 `~/.gemini/skills/`, `~/.agents/skills/`와 워크스페이스 경로 `.gemini/skills/`, `.agents/skills/`를 자동 인식합니다. 세 폴더를 복사한 뒤 `/skills reload`를 실행하거나 `/skills link <path> --scope user|workspace`, `gemini skills install <repository-url>`을 사용할 수 있습니다. 참고: [Gemini CLI Skills 공식 문서](https://geminicli.com/docs/cli/using-agent-skills/).
- **Google Antigravity**: `~/.gemini/config/plugins/` 아래에 세 스킬과 `mcp-server/hoi4_mcp.py`를 묶어 읽기 전용 로컬 플러그인으로 구성할 수 있습니다. Antigravity, Cursor, Claude Code, Gemini CLI처럼 내장 데스크톱 Computer Use가 없는 클라이언트에서 AI와 함께 HOI4 실기 검증을 진행하고 싶다면 프로세스 화이트리스트 기반 독립 MCP `hoi4_desktop`을 필요할 때만 켜서 연결하세요. 자세한 설정은 [데스크톱 MCP 설정 가이드](DESKTOP_MCP_SETUP_KO.md)에 정리되어 있습니다.

## 라이선스 안내

전체 스킬 세트는 **CC BY-SA 4.0**으로 통일해 배포합니다. 일반 개발 지침에 Millennium Dawn(CC BY-SA 4.0) 공개 자료의 정리·재구성이 포함되어 있어, 동일 라이선스 공유(ShareAlike)를 따르는 편이 깔끔하고 안전합니다. 저작자 표시, 변경 내역 명시, 동일 라이선스 공유를 지키면 복제·수정·상업적 이용이 가능합니다.

문서와 스크립트를 하나의 라이선스로 통일하면 사용자가 지켜야 할 조건도 훨씬 단순해집니다. 추후 독립 스크립트가 ShareAlike 유래 자료와 완전히 분리된다면 해당 코드만 MIT로 재검토할 수 있습니다. 본 라이선스는 이 저장소에 공개된 스킬 콘텐츠에 적용되며 Paradox Interactive, 다른 모드, 제3자 에셋은 각 원저작자의 권리를 유지합니다.
