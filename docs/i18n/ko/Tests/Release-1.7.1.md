> 과거 검증 기록의 개인 샘플 파일명은 익명화했습니다. 테스트 데이터와 결과는 그대로입니다.

<!-- doc-navigation:start -->
[문서 목록](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · **한국어** · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 검증 기록

버전 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. 앱과 세 내장 도구의 arm64 + x86_64 구조 및 로컬 서명을 검증했습니다. 이번에는 Apple Silicon 하드웨어에서 실행하지 않았습니다.

## 원인과 수정

사용자의 세 PSB는 8비트 RGB, 4채널, 합성 투명도가 있는 RLE이며 약 108–123 MiB였습니다. 파일 대부분은 건너뛸 수 있는 레이어 데이터이며 주 캔버스는 약 850–960만 픽셀입니다.

1. 이전 행 디코더는 PackBits 표식과 값마다 FileHandle 읽기를 하여 많은 작은 읽기가 주 화면·썸네일 큐를 오래 점유했습니다. 최대 64 KiB 블록 읽기로 바꾸고 블록 간 literal/run 상태 및 경계 검사를 유지했으며 긴 no-op도 취소할 수 있습니다. ZIP은 샘플링한 행만 예측 복원하지만 압축 스트림 전체 검증은 유지합니다.
2. 세 파일 모두 리소스 1036에 유효한 RGB JPEG 썸네일이 있습니다. 이제 필름스트립이 우선 사용하며 형식, 크기, 종횡비, 압축 길이를 검사합니다. 주 화면은 항상 실제 합성 이미지를 디코딩합니다. 잘못된 미리 보기, 구형 BGR 리소스, 미리 보기 부재 시 합성 이미지로 대체합니다.
3. 시스템 ImageIO는 일부 유효한 Generic RGB ICC가 있는 작은 PSD 합성 데이터를 거부해 이전 버전은 빈 썸네일을 반환했습니다. 이제 픽셀을 따로 디코딩한 후 검증된 색 모델·성분이 일치하는 원래 ICC를 다시 붙이며 프로파일을 버리지 않습니다. 원본 ICC는 시스템 표준 Generic RGB Profile과 같고 새 회귀 테스트는 시스템 프로파일로 생성한 자료를 써 사용자 사진을 소스에 넣지 않았습니다.
4. PSB 주 화면은 해석된 헤더를 재사용하고 메타데이터 때문에 ImageIO로 레이어를 추가 검색하지 않습니다. 원본 크기, 투명도, 주 화면 품질은 유지합니다.

## 세 원본 실측

이 Mac의 로컬 테스트로 시스템 부하와 파일 캐시의 영향을 받으며 모든 기기의 성능 보장이 아닙니다. 신구 디코더 모두 최적화 컴파일을 썼습니다.

| 파일 | 원본 크기 | 이전 주 화면 디코딩 | 새 주 화면 디코딩 | 새 합성 썸네일 디코딩(내장 미리 보기 없는 경로) |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | 15초 초과 후 테스트가 취소 | 0.68초 | 0.039초 |
| Sample B | 2610 × 3307 | 14.35초 | 0.65초 | 0.028초 |
| Sample C | 2843 × 3361 | 15초 초과 후 테스트가 취소 | 0.70초 | 0.028초 |

실제 ImageLoader로 세 썸네일을 동시 요청해 약 0.06초에 완료했습니다. 전체 주 화면은 로더로 약 0.90 / 0.65 / 0.74초였습니다. 이전 세 합성 썸네일은 모두 unsupported였고 새 버전은 모두 성공했습니다. 원본 바이트 SHA-256은 테스트 전후 같으며 앱이 원본에 기록하지 않았습니다.

## 이번 통과 검사

| 항목 | 결과 |
| --- | --- |
| PSD / PSB 인코딩과 투명 합성 | 712 / 712 |
| RLE 성능, 내장 미리 보기, ICC, 블록 간 처리, 취소 | 54 / 54 |
| 세 원본 PSB의 실제 ImageLoader 통합 | 21 / 21 |
| 443개 파일 필름스트립, 캐시, 무효 콜백 | 37 / 37 |
| 독립 썸네일 요청과 취소 | 13 / 13 |
| 이미지 라이브러리와 시스템 디코딩 | 78 / 78 |
| 설치된 최적화 배포본 오른쪽 클릭과 복사 | 28 / 28 |
| 합계 | 943 / 943 |

새 테스트는 조밀한 단일 바이트 literal, 64 KiB 경계, 긴 no-op 취소, 잘림·범위 초과, 내장 썸네일·주 이미지 각각의 올바른 내용, ICC, 투명도, 작은 크기의 비정수 배율을 다룹니다. 기존 112개 인코딩 조합과 128개 레이어 투명 표식 구조 샘플도 계속 통과합니다. 썸네일 막대는 빠른 전환, 화면 밖 취소, 오래된 콜백의 현재 목록 오염 방지를 검사합니다.

정식 설치본과 outputs/LumaView.app의 전체 목록·해시는 같으며 모두 codesign --verify --deep --strict를 통과했습니다. 설치 전 이전 ZIP을 보관했고 기본 연결은 변경하지 않았습니다. 배포 ZIP CRC와 버전은 별도 확인합니다. 전체 1.7.0 보고서는 Tests/Release-1.7.0.md에 보존하며 재실행하지 않은 검사는 이번에 넣지 않습니다.

주 실행 파일 SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## 로그

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
