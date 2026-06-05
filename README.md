# 재웅의 AI OS Template

GitHub 저장소를 AI 작업 운영체제처럼 쓰기 위한 템플릿입니다.

이 템플릿은 새 프로젝트 또는 기존 프로젝트에 다음을 설치합니다.

- `AGENTS.md`와 `harness/ai-rules.md` 기반 에이전트 운영 규칙
- GitHub Issues 기반 AI 작업 큐
- `ready-for-ai` 라벨 기반 작업 가능 상태
- 대화 내용을 GitHub 이슈로 등록하는 CLI
- GitHub Actions pre/post hook
- 라벨 자동 동기화
- 설치, 업그레이드, smoke test 스크립트

## 빠른 시작

기존 프로젝트에서는 아래 한 줄로 설치합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/Kojaewoong0504/KO-AI-OS/main/install.sh \
  | bash -s -- --target . --name my-project --domain "SaaS backend"
```

로컬에 템플릿 저장소를 clone한 상태라면:

```bash
./install.sh --target /path/to/project --name my-project --domain "SaaS backend"
```

`install.sh`는 `ai-os.project.yml`이 없으면 기본 프로파일을 자동으로 만들고, 있으면 그 파일을 사용합니다. 기존 파일은 기본적으로 보존하며, 정말 덮어써야 할 때만 `--force`를 붙입니다.

설치 후 정적 점검:

```bash
scripts/smoke-test-github-setup.sh --repo .
```

GitHub 원격에서 실제 pre-hook까지 점검:

```bash
scripts/live-smoke-github-issue.sh --repo OWNER/REPO
```

## GitHub Template으로 사용

1. GitHub에서 이 저장소의 **Use this template** 버튼으로 새 저장소를 만듭니다.
2. 저장소 루트에서 `./install.sh --target . --name my-project --domain "..."`를 실행합니다.
3. 필요하면 생성된 `ai-os.project.yml`을 수정합니다.
4. `scripts/smoke-test-github-setup.sh --repo .`로 로컬 설정을 확인합니다.
5. GitHub에서 `AI OS Label Sync` workflow를 실행합니다.

`ai-os.project.yml`은 로컬 프로젝트 설정 파일이므로 `.gitignore`에 포함되어 있습니다. 필요하면 프로젝트 정책에 따라 별도로 추적하세요.

## 프로젝트 프로파일

`ai-os.project.yml`은 `AGENTS.md`와 프로젝트별 `harness/ai-rules.md`를 생성하는 입력입니다.

예시:

```yaml
project:
  name: my-service
  domain: SaaS backend
  stack:
    - Python
    - FastAPI
    - PostgreSQL

agent:
  work_queue: github-issues
  issue_protocol: harness/github-issue-protocol.md
  rules_file: harness/ai-rules.md

constraints:
  - Never hardcode secrets
  - Do not change public API contracts without tests

verification:
  commands:
    - pytest
    - npm test
```

처음 설치는 보통 `install.sh`로 충분합니다. `AGENTS.md`만 다시 생성해야 할 때는 하위 도구를 직접 실행합니다.

```bash
scripts/init-ai-os.sh --profile ai-os.project.yml --output .
```

기존 `AGENTS.md`를 덮어쓰려면:

```bash
scripts/init-ai-os.sh --profile ai-os.project.yml --output . --force
```

## 포함 파일

```text
.github/
├── ISSUE_TEMPLATE/
│   ├── ai-task.yml
│   └── gc-task.yml
├── labels.yml
└── workflows/
    ├── label-sync.yml
    ├── pre-hook.yml
    ├── post-hook.yml
    └── gc-reminder.yml

harness/
├── ai-rules.md
├── github-issue-protocol.md
├── github-mcp-protocol.md
├── pre-hooks.md
├── post-hooks.md
└── gc-checklist.md

memory/
├── decisions/README.md
├── mistakes/README.md
└── patterns/README.md

scripts/
├── bootstrap-ai-os.sh
├── create-ai-issue.sh
├── generate-issue-draft.sh
├── init-ai-os.sh
├── list-ready-ai-issues.sh
├── live-smoke-github-issue.sh
├── smoke-test-github-setup.sh
├── upgrade-ai-os.sh
└── verify-work-queue.sh

templates/
└── agents/

AI_OS_VERSION
ai-os.project.example.yml
docs/github-smoke-test.md
install.sh
skills/README.md
```

## 포함하지 않는 파일

이 템플릿의 자체 검증용 `tests/` 폴더는 GitHub Template으로 배포하지 않습니다.

이유:

- `tests/`는 템플릿 자체의 테스트이지, 템플릿을 적용한 프로젝트의 테스트가 아닙니다.
- 새 프로젝트는 자기 테스트 폴더를 직접 만들고 추적해야 합니다.
- 그래서 `tests/`는 tracked 파일에서 제거했고, 이 저장소 로컬에서는 `.git/info/exclude`로만 제외합니다.

또한 `docs/superpowers/` 같은 에이전트 작업 계획/설계 산출물은 재사용 템플릿 런타임이 아니므로 `.gitignore`에 포함되어 있습니다.

## GitHub Issue 작업 큐

이 템플릿의 작업 큐 정본은 GitHub Issues입니다.

작업 가능 이슈:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

라벨 의미:

| 라벨 | 의미 |
| --- | --- |
| `ai-task` | AI가 처리할 작업 |
| `ready-for-ai` | pre-hook 검증을 통과해 작업 가능 |
| `needs-clarification` | 목적, 수락 기준, 범위가 부족함 |
| `blocked` | 외부 입력이나 의존성 때문에 진행 불가 |

## GitHub Actions

### Label Sync

`.github/labels.yml`의 표준 라벨을 GitHub 저장소에 생성/갱신합니다.

```bash
gh workflow run label-sync.yml --repo OWNER/REPO
```

### Pre-hook

`ai-task` 라벨이 붙은 이슈가 생성/수정될 때 실행됩니다.

| 상태 | 자동 처리 |
| --- | --- |
| 목적/수락 기준/범위 누락 | `needs-clarification` 추가, `ready-for-ai` 제거 |
| 목적/수락 기준/범위 입력 완료 | `ready-for-ai` 추가, `needs-clarification` 제거 |

### Post-hook

`ai-task` 이슈가 닫힐 때 완료 체크리스트 코멘트를 남깁니다.

### GC Reminder

정기적으로 코드/하네스 정리 이슈를 생성합니다.

## 이슈 생성

GitHub CLI 인증:

```bash
gh auth login
```

CLI 인자로 바로 생성:

```bash
scripts/create-ai-issue.sh \
  --title "[AI] 작업 제목" \
  --purpose "이 작업의 목적" \
  --criteria "완료 조건 1" \
  --criteria "완료 조건 2" \
  --scope-include "이번 이슈에서 처리할 범위" \
  --scope-exclude "이번 이슈에서 제외할 범위" \
  --constraints "지켜야 할 제약" \
  --context "관련 파일 또는 이전 결정" \
  --expected-output "코드 변경 / 문서 / 분석 리포트"
```

이슈 초안 파일 생성 후 등록:

```bash
scripts/generate-issue-draft.sh \
  --title "[AI] 작업 제목" \
  --purpose "이 작업의 목적" \
  --criteria "완료 조건" \
  --scope-include "포함 범위" \
  --output issue.yml

scripts/create-ai-issue.sh --from-file issue.yml
```

준비된 작업 큐 조회:

```bash
scripts/list-ready-ai-issues.sh
```

## MCP/Connector 사용

MCP는 필수가 아닙니다. 기본 경로는 `gh` CLI입니다.

GitHub MCP 또는 Connector가 연결되어 있으면 같은 규칙을 유지한 채 MCP 도구로 대체할 수 있습니다.

- 이슈 생성 시 `ai-task` 라벨 사용
- 본문 형식은 `harness/github-issue-protocol.md` 준수
- 작업 큐 조회는 `ai-task + ready-for-ai`
- `ready-for-ai`는 직접 붙이지 않고 pre-hook에 맡김

세부 규칙은 `harness/github-mcp-protocol.md`를 따릅니다.

## 기존 프로젝트 설치

```bash
curl -fsSL https://raw.githubusercontent.com/Kojaewoong0504/KO-AI-OS/main/install.sh \
  | bash -s -- --target . --name my-project --domain "SaaS backend"
```

기본 정책:

- 기존 파일은 보존
- 없는 파일만 복사
- `AGENTS.md`는 `init-ai-os.sh`로 생성
- `harness/ai-rules.md`는 프로젝트 프로파일 기반으로 생성
- `docs/superpowers/`는 설치하지 않음

프로파일을 먼저 직접 작성한 뒤 설치하려면:

```bash
./install.sh --target . --profile ai-os.project.yml
```

하위 bootstrap 스크립트를 직접 호출할 수도 있습니다.

```bash
scripts/bootstrap-ai-os.sh --profile ai-os.project.yml --target .
```

덮어쓰기:

```bash
./install.sh --target . --profile ai-os.project.yml --force
```

## 업그레이드

이미 AI OS가 설치된 프로젝트를 최신 템플릿 파일로 갱신합니다.

```bash
scripts/upgrade-ai-os.sh --target /path/to/project
```

기본 정책:

- 기존 파일은 보존
- `AI_OS_VERSION`은 최신 버전으로 갱신
- `harness/ai-rules.md`는 프로젝트별 파일이므로 덮어쓰지 않음
- `docs/superpowers/`는 설치하지 않음

강제 덮어쓰기:

```bash
scripts/upgrade-ai-os.sh --target /path/to/project --force
```

## 검증

로컬 정적 점검:

```bash
scripts/smoke-test-github-setup.sh --repo .
scripts/verify-work-queue.sh
```

실제 GitHub Actions 점검:

```bash
scripts/live-smoke-github-issue.sh --repo OWNER/REPO
```

이 스크립트는 임시 `ai-task` 이슈를 만들고, pre-hook이 `ready-for-ai`를 붙이는지 확인한 뒤 이슈를 닫습니다.

## 하네스 강화 루프

```text
AI 실수
-> memory/mistakes/ 기록
-> 패턴 분석
-> memory/patterns/ 또는 memory/decisions/ 기록
-> harness/ai-rules.md 업데이트
```

이 루프가 작동하면 프로젝트는 사용할수록 더 구체적인 AI 작업 운영체제가 됩니다.
