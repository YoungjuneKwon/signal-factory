# Signal Factory - 상세 기획 문서

이 폴더는 Signal Factory 프로젝트의 상세 기획 문서를 포함합니다.

## 문서 구조

모든 문서는 계층적 구조로 작성되어 있으며, 각 문서 간 링크로 연결되어 있습니다.

### 시작점

**[00_overview.md](./00_overview.md)** - 전체 프로젝트 개요 및 다른 문서로의 링크

### 문서 목록

1. **[00_overview.md](./00_overview.md)** - 프로젝트 총람
2. **[01_architecture_overview.md](./01_architecture_overview.md)** - 시스템 아키텍처
3. **[02_data_pipeline.md](./02_data_pipeline.md)** - 데이터 수집 및 처리
4. **[03_signal_generation.md](./03_signal_generation.md)** - 신호 생성 시스템
5. **[04_execution_engine.md](./04_execution_engine.md)** - 실행 엔진
6. **[05_web_ui.md](./05_web_ui.md)** - 웹 인터페이스
7. **[06_mobile_app.md](./06_mobile_app.md)** - 모바일 앱 (Expo)
8. **[07_security.md](./07_security.md)** - 보안 및 격리
9. **[08_deployment.md](./08_deployment.md)** - 배포 및 운영
10. **[09_api_specifications.md](./09_api_specifications.md)** - API 명세
11. **[10_data_models.md](./10_data_models.md)** - 데이터 모델
12. **[11_tech_stack.md](./11_tech_stack.md)** - 기술 스택
13. **[12_user_workflows.md](./12_user_workflows.md)** - 사용자 워크플로우
14. **[13_business_model.md](./13_business_model.md)** - 비즈니스 모델
15. **[14_roadmap.md](./14_roadmap.md)** - 개발 로드맵

## 주요 특징

### 📋 상세한 내용
- PROJECT_PLAN.md의 모든 내용을 분석하여 재구성
- 각 주제별로 심도 있는 기술 상세 포함
- 실제 코드 예제 및 구현 가이드 제공

### 🔗 계층적 구조
- 메인 개요 문서에서 시작
- 각 세부 주제별 독립 문서
- 문서 간 링크로 쉬운 탐색

### 💾 최적화된 데이터 구조
- 방대한 시세 데이터 처리를 위한 최적화
- 압축 포맷 (배열 기반, Delta Encoding, Protocol Buffers)
- 키값 및 메타데이터 최소화

### 🛠️ 기술 중심
- JavaScript, React, Expo 중심
- 필요시 Python, Rust 활용
- 백엔드-프론트엔드 분리 아키텍처

### 🔐 보안 강조
- 샌드박스 로직 실행
- 데이터 암호화
- 감사 로깅

## PDF 생성

통합 PDF 문서를 생성하려면:

```bash
cd docs
./generate_pdf.sh
```

생성된 파일: `signal_factory_planning_docs.pdf`

**요구사항**: Pandoc 및 XeLaTeX (스크립트가 자동 설치 시도)

## 파일 명명 규칙

모든 파일명은 다음 규칙을 따릅니다:
- 숫자로 시작 (정렬 순서)
- 영문 소문자, 숫자, 언더바(`_`), 하이픈(`-`), 점(`.`)만 사용
- 확장자: `.md`

예: `01_architecture_overview.md`

## 문서 버전

- **버전**: 1.0.0
- **생성일**: 2025-11-03
- **작성 근거**: PROJECT_PLAN.md 전체 분석
- **언어**: 한국어 (주), 영어 (코드 및 기술 용어)

## 기여

문서 개선 사항이 있으면 PR을 제출해주세요.

## 라이선스

Signal Factory 프로젝트의 일부로, 프로젝트 라이선스를 따릅니다.
