> 과거 검증 기록의 개인 샘플 파일명은 익명화했습니다. 테스트 데이터와 결과는 그대로입니다.

<!-- doc-navigation:start -->
[문서 목록](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · **한국어** · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 검증 기록

날짜: 2026-10-22(Asia/Shanghai). 이번 환경: macOS 15.7.9, x86_64. 앱 대상은 macOS 13+이며 네 실행 파일 모두 Intel / Apple Silicon 유니버설입니다.

## 변경 및 실측 결과

- Ghostscript 10.08.0을 내장했습니다. EPS, PostScript, 구형 PostScript AI를 직접 열면 벡터 경로·텍스트·원래 내장 이미지를 보존한 PDF를 백그라운드에서 생성해 기존 캔버스로 넘깁니다. 별도 해석기 설치나 수동 변환 없이 기존 확대·이동·회전·다중 페이지 조작을 사용합니다. 벡터 변환이 실패하고 파일에 미리 보기가 있으면 내장 TIFF 대체를 유지하며 래스터를 벡터로 표시하지 않습니다.
- 원래 첨부 `sample-vector.eps`의 전체 PostScript 내용 사용을 확인했습니다. 생성 PDF에서 **147,521회 경로 / 그라데이션 관련 연산, 59회 텍스트 연산, 160회 XObject 호출**을 찾았습니다. XObject는 PDF `Do` 호출 수이며 이미지나 Form을 포함하므로 독립 이미지 장수와 같지 않습니다. 실제 벡터 보존을 확인했고 원 EPS와 `sample-vector.svg`는 테스트 전후 SHA-256이 같아 수정되지 않았습니다.
- PostScript는 취소 가능한 독립 프로세스, Ghostscript SAFER, 시스템 프로세스 샌드박스를 사용합니다. 입력을 전용 임시 폴더로 복사하며 다른 사용자 파일 읽기, 임의 외부 파일 쓰기, 외부 파이프를 금지합니다. 시간 제한·취소·다중 소비자 재사용·손상 입력·캐시 무효화 검사를 통과했습니다. 결과는 완료 후 원자적으로 공개하며 부분 PDF로 썸네일을 채우지 않습니다. 실제 뷰어에서 EPS 3200% 벡터 확대, 다중 페이지 PS의 위아래 초점·좌우 이동, 변환 중 PNG로 전환 후 오래된 결과가 화면을 덮지 않는지 검증했습니다.
- Photoshop 형식 그룹에 `.psb`를 추가하여 `.psd`와 함께 검색, 주 화면, 썸네일, 기본 앱 설정에 사용합니다. 호환 합성 이미지를 읽고 원본 캔버스 크기를 유지하며 큰 파일은 표시 요구에 맞는 제한된 미리 보기를 만듭니다. **112개 인코딩 조합, 128개 레이어 투명 표식 구조 샘플, 1개 대형 PSB, 13개 손상 샘플**을 검증했습니다. 레이어 수와 Lr16/Lr32, Mtrn/Mt16/Mt32로 합성 투명도를 구분하여 일반 추가 Alpha를 오인하지 않습니다. 투명 픽셀 수치, 흰 바탕 제거, 인코딩 일치, 큰 행 취소, 주 화면 / 썸네일 통합 회귀도 포함합니다.
- 기본 앱 대화상자는 열기, 앱 재활성화, 일괄 설정 완료 때 실제 시스템 연결을 읽습니다. 연결 자체는 재시작 후에도 유지되며 미적용 초안을 성공으로 간주하지 않습니다. 모든 유형이 현재 앱이면 체크, 일부만 일치하거나 같은 bundle ID의 다른 사본이면 가로선과 설명을 표시합니다. 비우기는 초안만 바꾸고 시스템 연결을 해제하지 않습니다.
- 상단 “모든 형식 선택”은 검색 밖을 포함한 이미지, 벡터 / 문서, 비디오, 오디오를 한 번에 선택하지만 설정 버튼을 눌러야 연결을 기록합니다. 감지, 부분 성공, 실패 읽기, 컨트롤러 재생성, 초안·실제 상태 구분, 전체 선택은 메모리 mock 백엔드로 검증했으며 사용자 기본 앱을 변경하지 않았습니다.
- 새 설정, PostScript, Photoshop 문구는 16개 언어를 모두 포함하고 필수 문구 및 자리표시자 검사를 통과했습니다.

## 이번 검증

아래의 완전한 성공 요약이 있는 이번 로그만 집계합니다. 재실행하지 않은 과거 모듈은 포함하지 않습니다.

| 검사 | 통과 |
| --- | --- |
| PostScript 벡터 변환, 취소, 격리, 실제 EPS | 24 / 24 |
| SVG / EPS 호환 및 원 첨부 검증 | 64 / 64 |
| PSD / PSB 합성, 투명 채널, 대형 이미지, 손상 데이터 | 712 / 712 |
| 기본 앱 시스템 읽기 및 일괄 설정(mock) | 101 / 101 |
| 기본 형식 창, 재열기 상태, 모든 형식 선택(mock) | 34 / 34 |
| 16개 언어와 자리표시자 | 174 / 174 |
| 배포 앱 형식 선언 | 15 / 15 |
| 이미지 라이브러리와 시스템 디코딩 | 78 / 78 |
| 캔버스 기하, 애니메이션, 마우스 | 66 / 66 |
| 문서 해석과 전체 페이지 그리기 | 56 / 56 |
| 문서 초점, EPS / PS 확대·페이지 이동, 취소·파일 전환 | 75 / 75 |
| 실제 창 클릭과 수명 주기 | 65 / 65 |
| 443개 파일 썸네일, 캐시, 만료 콜백 | 37 / 37 |
| 썸네일 요청 취소와 소비자 격리 | 13 / 13 |
| 정식 설치 배포본 오른쪽 클릭과 전용 클립보드 | 28 / 28 |
| **합계** | **1542 / 1542** |

정식 설치된 최적화 배포본에 실제 메뉴와 target/action 전달, 별도 이름의 클립보드로 오른쪽 클릭 28개 검사를 수행했습니다. 이미지, 비디오 현재 프레임, PDF 이미지와 전체 페이지, 회전, 전환 / 닫기 시 오래된 결과 처리를 검증했으며 시스템 클립보드는 덮지 않았습니다. 기존 마우스 클릭, 창 수명 주기, 페이지 초점, 완전 페이지 표시, 썸네일 캐시·취소 회귀도 통과했습니다.

## 배포 폴더와 설치본 검증

버전 **1.7.0, build 12**. 보고서 전 `outputs/LumaView.app`과 `/Applications/LumaView.app`의 bundle ID, 버전, build, 전체 파일 목록, SHA-256을 비교했으며 내용이 일치했습니다. 네 실행 파일은 두 아키텍처 검사, 두 앱은 `codesign --verify --deep --strict`를 통과했습니다. 내장 Ghostscript는 10.08.0으로 보고하며 언어·버전 리소스가 소스 폴더와 같고 Ghostscript 소스 SHA-256도 동봉 목록과 일치했습니다. 빌드 시 해석기를 재서명하므로 서명한 바이너리가 소스 폴더의 미재서명 사본과 바이트 단위로 같을 필요는 없습니다.

| 실행 파일 | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

이 보고서는 이후 ZIP 무결성 검사를 대신하지 않으며 Apple 공증을 주장하지 않습니다. 서명은 로컬 임시 서명입니다. Apple Silicon은 교차 컴파일과 아키텍처 검사만 했고 이번에는 실기기에서 실행하지 않았습니다. Ghostscript 소스 압축 파일, 라이선스, 재빌드 안내를 소스와 함께 제공합니다.

## 범위와 한계

EPS / PS에 원래 포함된 비트맵은 자체 해상도에 제한됩니다. 외부 글꼴·파일 리소스, 특수하거나 손상된 PostScript의 완전 변환을 보장하지 않습니다. PSD / PSB는 호환 합성 이미지에 의존하며 Photoshop 레이어 편집이나 누락 합성 재구성을 하지 않습니다. 없으면 “호환성 최대화”로 다시 저장하도록 안내합니다. 원본 캔버스는 실제 미리 보기보다 클 수 있으며 제한된 미리 보기를 모든 원본 픽셀의 완전 디코딩이라 하지 않습니다. 다른 형식 제한은 [FORMATS.md](../FORMATS.md)를 참고하세요.

## 이번 로그 출처

다음 파일을 `Tests/`로 복사했습니다. 재실행하지 않은 과거 보고서도 보관하지만 이번 합계에는 넣지 않습니다:

- `PostScript-test-results.txt` ← `work/postscript-17/postscript-test-results.txt`
- `vector-compatibility-test-results.txt` ← `work/vector-compatibility-1.7.0/vector-compatibility-test-results.txt`
- `Photoshop-test-results.txt` ← `work/psb-support/results.txt`
- `Default-application-test-results.txt` ← `work/default-application-1.7-results.txt`
- `Default-preferences-test-results.txt` ← `work/default-preferences-tests/default-preferences-test-results.txt`
- `Localization-test-results.txt` ← `work/localization-1.7-results.txt`
- `Media-declaration-test-results.txt` ← `work/media-declaration-1.7.0.txt`
- `Core-test-results.txt` ← `work/core-1.7.0-run.log`
- `Canvas-test-results.txt` ← `work/canvas-1.7.0-run.log`
- `Document-core-test-results.txt` ← `work/document-1.7.0/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-1.7.0/document-test-results.txt`
- `UI-test-results.txt` ← `work/ui-1.7.0/ui-test-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.0/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.0-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.0/context-menu-test-results.txt`
