# LumaView 1.7.2 검증 기록

<!-- doc-navigation:start -->
[문서 목록](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · **한국어** · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


버전 1.7.2, build 14. 2026-10-22, macOS 15.7.9 / Intel. 앱과 내장 도구의 arm64 + x86_64 유니버설 구조와 로컬 서명을 검증했으며 이번에는 Apple Silicon 하드웨어에서 실행하지 않았습니다.

## 이번 수정

래스터 이미지 투명 영역을 모두 직접 표시합니다. PNG / GIF / PSD / PSB 등에 체크무늬나 캔버스 사각 테두리를 덧붙이지 않습니다. 그림자는 캔버스 전체가 아닌 실제 합성 투명도에서 만들어져 투명 여백에 추가 사각 그림자가 없으며 구멍, 독립 소프트 마스크, 반투명 영역도 윤곽에 반영됩니다.

기존 구현은 CGImage.alphaInfo만 보고 체크무늬를 추가해 독립 Quartz mask가 있는 PSB를 놓쳤습니다. 확대할 때마다 사각 shadowPath를 강제 설치하고 테두리 자체도 사각 그림자를 만들었습니다. 이제 이런 사각형 요소를 없애고 합성 alpha가 레이어 그림자를 자동 생성합니다. 그리기 내보내기도 사각형을 먼저 채우지 않고 이미지 자체에 그림자를 줍니다. GIF / APNG는 현재 텍스처를 계속 교체하며 그림자도 프레임에 따라 갱신합니다. 매 프레임 투명 픽셀을 검색하거나 전체 RGBA 이미지를 추가 생성할 필요가 없습니다.

문서의 흰 종이와 비디오 사각 표면은 기존 표시를 유지합니다. 이미지 복사는 원본 픽셀을 사용하고 보기 배경, 체크무늬, 표시용 그림자를 넣지 않습니다. PSB 디코더, 썸네일 스케줄링, 이전 버전의 빠른 미리 보기는 바꾸지 않았습니다.

## 이번 검증

| 항목 | 통과 |
| --- | --- |
| 투명 영역, 윤곽 그림자, 프레임 전환 | 133 / 133 |
| 캔버스 기하, 애니메이션, 마우스 | 66 / 66 |
| 문서 해석과 전체 페이지 렌더링 | 56 / 56 |
| 정식 설치본 문서, EPS / PS 확대·페이지 이동·초점 | 75 / 75 |
| 정식 설치본 오른쪽 클릭 메뉴와 복사 | 28 / 28 |
| 합계 | 358 / 358 |

투명 테스트는 구멍, 불규칙 돌출부, 큰 투명 여백이 있는 같은 도형을 RGBA, 독립 Quartz mask, 실제 인코딩·디코딩한 PNG, GIF, PSD, PSB로 사용했습니다. CALayer 합성과 draw 내보내기 픽셀에서 투명 가장자리에 사각 바탕 / 그림자가 없고 안팎 윤곽에 그림자가 있는지 검증했습니다. 완전 투명 이미지, 프레임 변경, 회전·확대, 빠른 전환, 반투명 보기 배경도 검사했고 내보낸 PNG를 육안으로 확인했습니다.

이 6개 입력의 CALayer 내보내기와 PNG draw 내보내기 PNG SHA-256은 모두 같습니다: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. 테스트 자료는 코드로 생성했으며 사용자 사진을 소스에 넣지 않았습니다.

추가로 제한된 소프트웨어 렌더링 프로브를 실행했습니다. 32 MP 비트맵, 논리 캔버스 16,384 × 7,812와 300,000 × 128을 창 맞춤, 100%, 3200%에서 신구 그림자로 비교했습니다. 최고 RSS는 약 428 MiB이며 렌더링 시간은 비슷했습니다. 이는 CALayer.render(in:) 소프트웨어 스냅샷 비용이지 GPU 프레임률 결론은 아닙니다. 이 결과로 레이어 래스터 캐시를 추가하지 않았습니다.

정식 설치본과 outputs/LumaView.app의 전체 파일 목록·해시는 같으며 모두 codesign --verify --deep --strict를 통과했습니다. 설치 전 이전 ZIP을 보관했고 기본 연결을 전후 다시 읽어 비교했습니다. 배포 ZIP은 이후 CRC와 버전을 검증했습니다. 과거 보고서는 Tests/Release-1.7.0.md와 Tests/Release-1.7.1.md에 남겼으며 재실행하지 않은 과거 검사는 이번 수에 넣지 않았습니다.

주 실행 파일 SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## 로그 출처

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
