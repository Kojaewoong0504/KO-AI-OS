# 재웅의 AI OS — Template Repository

새 프로젝트를 시작할 때 이 템플릿을 사용하면 AI OS 전체가 자동으로 설치됩니다.

## 설치 방법

### 방법 1: GitHub Template으로 새 프로젝트 시작

1. 이 저장소 상단의 **"Use this template"** 버튼 클릭
2. 새 저장소 이름 입력 후 생성
3. `harness/ai-rules.md`를 프로젝트에 맞게 수정

### 방법 2: 기존 프로젝트에 추가

```bash
# 기존 프로젝트 루트에서 실행
# .github/, harness/, memory/, skills/ 디렉토리만 복사
git clone https://github.com/{your-username}/ai-os-template tmp-ai-os
cp -r tmp-ai-os/.github .
cp -r tmp-ai-os/harness .
cp -r tmp-ai-os/memory .
cp -r tmp-ai-os/skills .
rm -rf tmp-ai-os
```

---

## 포함된 파일 구조

```
.github/
├── ISSUE_TEMPLATE/
│   ├── ai-task.yml          # AI 작업 이슈 템플릿
│   └── gc-task.yml          # GC 이슈 템플릿
└── workflows/
    ├── pre-hook.yml         # 이슈 생성 시 자동 린트
    ├── post-hook.yml        # 이슈 닫을 때 체크리스트
    └── gc-reminder.yml      # 매주 GC 이슈 자동 생성

harness/
├── ai-rules.md              # AI 작업 규칙 (핵심)
├── github-issue-protocol.md # 대화 → GitHub 이슈 등록 규칙
├── pre-hooks.md             # 작업 전 체크리스트
├── post-hooks.md            # 작업 후 체크리스트
└── gc-checklist.md          # GC 주기 가이드

memory/
├── mistakes/README.md       # AI 실수 기록 가이드
├── patterns/README.md       # 좋은 패턴 기록
└── decisions/README.md      # 설계 판단 기록 (ADR)

skills/
└── README.md                # 스킬 추가 가이드

scripts/
├── create-ai-issue.sh       # 대화 내용을 ai-task 이슈로 등록
├── list-ready-ai-issues.sh  # ready-for-ai 작업 큐 조회
└── verify-work-queue.sh     # 작업 큐 계약 검증
```

---

## GitHub Actions 동작 방식

### Pre-hook (이슈 생성/수정 시)

ai-task 라벨이 붙은 이슈를 검사합니다.

| 상태 | 자동 처리 |
|-----------|--------------|
| 목적/수락 기준/범위 중 누락 있음 | `needs-clarification` 라벨 + 코멘트, `ready-for-ai` 제거 |
| 목적/수락 기준/범위 모두 입력됨 | `ready-for-ai` 라벨 + 통과 코멘트, `needs-clarification` 제거 |

AI 에이전트가 작업할 수 있는 이슈는 아래 쿼리로 찾습니다.

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

즉, `ai-task`만 붙은 이슈는 작업 큐가 아닙니다.
pre-hook을 통과해 `ready-for-ai`가 붙은 열린 이슈만 작업 가능 상태입니다.

## 에이전트 대화에서 이슈 등록

이 템플릿은 GitHub MCP 없이도 `gh` CLI로 이슈를 등록할 수 있습니다.

사전 조건:

```bash
gh auth login
```

대화 내용을 이슈로 등록:

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

준비된 작업 큐 조회:

```bash
scripts/list-ready-ai-issues.sh
```

GitHub MCP나 Connector가 연결된 환경에서는 같은 본문 형식과 라벨 규칙을 유지한 채 MCP 도구로 이슈를 생성해도 됩니다.
자세한 규칙은 `harness/github-issue-protocol.md`를 따릅니다.

### Post-hook (이슈 닫을 때)

이슈를 닫으면 체크리스트 코멘트가 자동으로 달립니다.
결과물 확인 → 리스크 확인 → 하네스 강화 순서로 점검합니다.

### GC 리마인더 (매주 월요일)

- 매주: 코드 GC 이슈 자동 생성
- 격주: 하네스 GC 이슈 자동 생성

---

## 프로젝트별 커스터마이징

harness/ai-rules.md 하단 도메인 컨텍스트 섹션을 반드시 프로젝트에 맞게 수정하세요.

```markdown
## 도메인 컨텍스트
- 주 작업 도메인: {이 프로젝트의 도메인}
- 기술 스택: {언어, 프레임워크}
- 주의사항: {이 프로젝트 특이사항}
```

---

## 하네스 강화 루프

```
AI 실수 → memory/mistakes/ 기록 → 패턴 분석 → harness/ai-rules.md 업데이트
```

이 루프가 작동하면 시스템은 쓸수록 강해집니다.
