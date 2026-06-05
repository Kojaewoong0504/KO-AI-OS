# Agent Workflow

이 문서는 AI OS가 설치된 저장소에서 에이전트가 작업을 시작하고 끝낼 때 읽는 단일 진입점이다.

## 기본 계약

- GitHub Issues가 작업 큐의 정본이다.
- 새 작업 요청은 먼저 `ai-task` 이슈로 정리한다.
- 작업 가능 여부는 GitHub Actions pre-hook이 판단한다.
- 에이전트는 `ready-for-ai` 라벨이 붙은 이슈만 작업한다.
- 작업 완료 보고는 이슈의 수락 기준과 검증 증거를 기준으로 한다.

## 대화에서 이슈 만들기

사용자가 새 작업을 요청하면 다음 정보를 추출한다.

- 제목: `[AI] ...` 형식의 짧은 작업명
- 목적: 왜 필요한 작업인지
- 수락 기준: 완료 여부를 판단할 체크리스트
- 포함 범위: 이번 이슈에서 처리할 일
- 제외 범위: 이번 이슈에서 하지 않을 일
- 제약: 변경 금지 영역, 유지해야 할 패턴, 보안 조건
- 참고 컨텍스트: 관련 파일, 결정 기록, 이전 이슈
- 예상 결과물: 코드, 문서, 분석 리포트 등

필수 정보인 목적, 수락 기준, 포함 범위가 부족하면 이슈를 만들기 전에 한 번만 짧게 질문한다.

기본 생성 경로:

```bash
scripts/create-ai-issue.sh \
  --title "[AI] 작업 제목" \
  --purpose "작업 목적" \
  --criteria "완료 조건" \
  --scope-include "포함 범위"
```

초안을 먼저 남겨야 할 때:

```bash
scripts/generate-issue-draft.sh \
  --title "[AI] 작업 제목" \
  --purpose "작업 목적" \
  --criteria "완료 조건" \
  --scope-include "포함 범위" \
  --output issue.yml

scripts/create-ai-issue.sh --from-file issue.yml
```

GitHub MCP나 Connector를 사용할 수 있으면 같은 본문 형식과 라벨 규칙으로 이슈를 만들어도 된다. MCP는 선택 사항이며 필수 의존성이 아니다.

## 작업 선택

준비된 작업 큐:

```text
is:issue is:open label:ai-task label:ready-for-ai -label:needs-clarification -label:blocked
```

작업 순서:

1. `scripts/list-ready-ai-issues.sh`로 준비된 이슈를 조회한다.
2. 사용자가 특정 이슈를 지정하지 않았다면 가장 오래된 준비 이슈를 우선한다.
3. 이슈 본문과 코멘트를 읽고 수락 기준을 완료 계약으로 삼는다.
4. 필요한 파일을 읽고, 가장 작은 안전한 변경 단위로 작업한다.
5. 수락 기준에 맞는 검증을 실행한다.
6. 변경 파일, 수락 기준 결과, 검증 증거, 남은 위험을 보고한다.

`needs-clarification` 또는 `blocked` 라벨이 있는 이슈는 작업하지 않는다. 필요한 정보가 생기면 이슈에 질문을 남기거나 별도 후속 이슈로 분리한다.

## 작업 중 규칙

- `harness/ai-rules.md`의 프로젝트별 규칙을 먼저 적용한다.
- `harness/github-issue-protocol.md`는 이슈 본문과 라벨 계약의 정본이다.
- `harness/github-mcp-protocol.md`는 MCP/Connector 사용 시 같은 계약을 지키는 방법이다.
- 새 범위가 발견되면 현재 이슈를 확장하지 말고 후속 이슈로 만든다.
- 시크릿, 토큰, 개인 인증 정보는 파일에 기록하지 않는다.

## 완료 보고

완료 코멘트 또는 최종 보고에는 다음을 포함한다.

- 변경 파일
- 수락 기준별 결과
- 실행한 검증 명령과 결과
- 남은 위험 또는 미검증 항목

이슈를 닫으면 post-hook이 완료 체크리스트 코멘트를 남긴다.
