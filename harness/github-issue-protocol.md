# GitHub Issue Protocol

이 문서는 에이전트가 사용자와의 대화를 GitHub `ai-task` 이슈로 변환할 때 따르는 규칙이다.

## 기본 원칙

- GitHub Issues가 작업 큐의 정본이다.
- 새 작업은 먼저 `ai-task` 이슈로 등록한다.
- 작업 가능 상태는 pre-hook이 판단한다.
- pre-hook을 통과하면 `ready-for-ai` 라벨이 붙는다.
- `ready-for-ai`가 없는 이슈는 작업하지 않는다.

## MCP 필요 여부

MCP는 필수가 아니다.

기본 경로:

```text
대화 내용 -> scripts/create-ai-issue.sh -> gh issue create -> GitHub Issue
```

GitHub MCP나 Connector가 연결된 환경에서는 같은 본문 형식과 라벨 규칙을 유지한 채 MCP 도구로 이슈를 생성해도 된다.

## 이슈 생성 규칙

사용자가 새 작업을 요청하면 에이전트는 아래 항목을 추출한다.

| 항목 | 설명 | 필수 |
| --- | --- | --- |
| 제목 | `[AI] ...` 형식의 짧은 작업명 | 예 |
| 목적 | 왜 이 작업이 필요한지 | 예 |
| 수락 기준 | 완료 여부를 판단할 체크리스트 | 예 |
| 포함 범위 | 이번 이슈에서 처리할 내용 | 예 |
| 제외 범위 | 이번 이슈에서 하지 않을 내용 | 권장 |
| 제약 | 건드리면 안 되는 영역, 유지할 패턴 | 권장 |
| 참고 컨텍스트 | 파일, 이전 결정, 관련 이슈 | 권장 |
| 예상 결과물 | 코드, 문서, 분석 리포트 등 | 권장 |

필수 항목이 부족하면 이슈를 만들기 전에 한 번만 짧게 질문한다.

## CLI 사용

```bash
scripts/create-ai-issue.sh \
  --title "[AI] 작업 제목" \
  --purpose "이 작업의 목적" \
  --criteria "완료 조건 1" \
  --criteria "완료 조건 2" \
  --scope-include "포함 범위" \
  --scope-exclude "제외 범위" \
  --constraints "제약 조건" \
  --context "참고 컨텍스트" \
  --expected-output "예상 결과물"
```

준비된 작업 큐 조회:

```bash
scripts/list-ready-ai-issues.sh
```

정본 쿼리:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

## 작업 선택 규칙

1. `scripts/list-ready-ai-issues.sh`로 준비된 이슈를 조회한다.
2. 사용자가 특정 이슈를 지정하지 않았다면 가장 오래된 이슈를 우선한다.
3. 이슈 본문과 코멘트를 읽고 수락 기준을 완료 계약으로 삼는다.
4. 작업 결과는 수락 기준 대비 체크리스트와 검증 증거로 보고한다.
