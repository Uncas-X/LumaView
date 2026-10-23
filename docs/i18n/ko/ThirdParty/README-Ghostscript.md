# Ghostscript 문서 변환 도구

<!-- doc-navigation:start -->
[문서 목록](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · **한국어** · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView는 Artifex가 2026-09-08 배포한 Ghostscript **10.08.0**을 독립 로컬 실행 파일로 호출해 EPS와 PostScript를 임시 PDF로 변환합니다. PDF는 지원되는 벡터 경로, 텍스트, 그라데이션을 보존하며 원래 래스터로 포함된 이미지는 래스터로 남습니다. Ghostscript는 Swift 앱에 링크하지 않으며 동봉 실행 파일을 사용하기 위해 Homebrew를 설치할 필요가 없습니다.

## 라이선스 및 대응 소스

Ghostscript는 해당 배포본의 원래 `LICENSE`에 따라 **GNU Affero General Public License 버전 3 이상**으로 배포합니다. 전체 라이선스, Ghostscript 저작권 고지, 글꼴 포함 예외, Adobe CMap 고지, 의존성 고지를 변경 없이 `Resources/ThirdPartyNotices/Ghostscript/`에 복사했습니다. Artifex의 별도 상용 라이선스도 있으나 이 패키지는 상용 라이선스를 포함하지 않습니다. [공식 라이선스 페이지](https://www.ghostscript.com/licensing/index.html)를 참고하세요.

동봉 의존성과 글꼴 소스를 포함한 정확한 미수정 대응 소스는 `ThirdParty/sources/ghostscript-10.08.0.tar.xz`에 있습니다. SHA-256은 `ThirdParty/sources/SHA256SUMS-Ghostscript`에 기록합니다:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

출처: [공식 배포 페이지](https://www.ghostscript.com/releases/index.html) 및 [Artifex 10.08.0 배포 자산](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). 체크섬은 `.tar.xz` 자산의 공개 값과 일치합니다. 소스 패키지와 빌드 스크립트는 LumaView 소스 배포에 포함됩니다. LumaView는 독립 도구 수정·교체와 이를 디버깅하는 역공학에 추가 제한을 두지 않습니다. 이 고지는 동봉된 제3자 구성 요소를 설명하며 앱 소스의 라이선스를 바꾸려는 것이 아닙니다.

## 재빌드

요구 사항: macOS, Xcode Command Line Tools, 동봉 소스 압축 파일, 표준 macOS 빌드 도구. Homebrew 라이브러리는 사용하지 않습니다. LumaView 소스 폴더에서 실행합니다:

```sh
./tools/build-document-tools.sh
./build.sh
```

스크립트는 소스를 검증하고 별도 소스 폴더에서 Intel과 Apple Silicon 슬라이스를 빌드해 로컬 심볼을 제거한 후 `Resources/DocumentTools/gs`로 합칩니다. 둘 다 macOS 13.0 이상을 대상으로 합니다. `make install`을 실행하거나 시스템 패키지 관리자에 기록하지 않습니다. `LUMAVIEW_DOCUMENT_BUILD`는 중간 폴더, `LUMAVIEW_DOCUMENT_JOBS`는 make 병렬 작업 수(기본 4)입니다. 선택 인수 `x86_64` 또는 `arm64`로 한 아키텍처만 빌드합니다. 앱 빌드는 복사한 실행 파일과 앱을 함께 서명합니다.

실행 파일은 내부 `%rom%` 파일 시스템에 초기화 코드, 동봉 글꼴, Adobe CMaps, ICC 프로파일을 포함합니다. 외부 기본 검색 경로는 비어 있으며 `pdfwrite` 출력 장치만 활성화합니다. 인쇄/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, 동적 드라이버, 외부 IJS, 문서 추출 도구는 비활성화합니다. 포함된 모든 디코더·색·글꼴 라이브러리는 대응 소스로 컴파일하며 동적 링크는 Apple 시스템 라이브러리로 제한합니다. ROM 및 교차 컴파일은 [공식 빌드 문서](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html)를 참고하세요.

LumaView는 `-dSAFER`, 지정 입력·출력, 비공개 임시 작업 폴더, 취소와 시간 제한을 사용해 해석기를 실행합니다. 프로세스 환경은 사용자 지정 Ghostscript 옵션이나 라이브러리 경로를 상속하면 안 됩니다. 신뢰할 수 있는 생성 테스트 자료의 예:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

전체 빌드 옵션은 `tools/build-document-tools.sh`에 있으며 소스 압축 파일은 패치하지 않습니다. 네이티브 실행 테스트는 빌드 호스트가 지원하는 아키텍처에서만 가능합니다. 배포 검사는 두 Mach-O 슬라이스를 검사하고 경로와 텍스트가 있는 생성 EPS를 호스트 호환 슬라이스로 처리하여 PDF에 벡터 그리기와 텍스트 연산자가 남는지 확인합니다.
