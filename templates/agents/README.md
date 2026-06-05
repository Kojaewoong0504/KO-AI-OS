# templates/agents

이 폴더는 `scripts/init-ai-os.sh`가 생성하는 에이전트 파일의 기준 틀을 설명한다.

현재 템플릿:

- `AGENTS.md.tpl`: 생성되는 `AGENTS.md`가 포함해야 할 필수 섹션
- `harness-ai-rules.md.tpl`: 생성되는 `harness/ai-rules.md`가 포함해야 할 필수 섹션

현재 생성 로직은 shell 스크립트 안에서 직접 문서를 렌더링한다. 이 폴더의 `.tpl` 파일은 생성 결과의 계약을 문서화하는 기준 파일이다.

향후 개선 방향:

- `init-ai-os.sh`가 이 템플릿 파일을 직접 읽어 렌더링하도록 전환
- 프로젝트 유형별 템플릿 추가
- 역할별 에이전트 운영 규칙 분리
