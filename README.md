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
├── pre-hooks.md             # 작업 전 체크리스트
├── post-hooks.md            # 작업 후 체크리스트
└── gc-checklist.md          # GC 주기 가이드

memory/
├── mistakes/README.md       # AI 실수 기록 가이드
├── patterns/README.md       # 좋은 패턴 기록
└── decisions/README.md      # 설계 판단 기록 (ADR)

skills/
└── README.md                # 스킬 추가 가이드
```

---

## GitHub Actions 동작 방식

### Pre-hook (이슈 생성/수정 시)

ai-task 라벨이 붙은 이슈를 검사합니다.

| 검사 항목 | 비어있을 경우 |
|-----------|--------------|
| 목적 | needs-clarification 라벨 + 코멘트 |
| 수락 기준 | 동일 |
| 범위 | 동일 |

모든 항목이 채워지면 통과 코멘트를 남깁니다.

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
