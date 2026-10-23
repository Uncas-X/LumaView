# 내장 미디어 도구

<!-- doc-navigation:start -->
[문서 목록](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · **한국어** · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView는 변경하지 않은 FFmpeg 9.0.2와 ffprobe를 독립 로컬 프로세스로 호출합니다. macOS 13을 대상으로 Intel과 Apple Silicon용 소스 빌드를 제공합니다. AV1 디코딩은 정적 링크한 dav1d 1.5.3을 사용하며 동적 라이브러리는 시스템 것만 사용합니다. 실행 시 Homebrew와 VLC는 필요 없습니다.

FFmpeg는 LGPL 2.1 이상으로 구성하며 `--enable-gpl`과 `--enable-nonfree`는 사용하지 않습니다. dav1d는 BSD 2-Clause입니다. 전체 라이선스 고지는 `Resources/ThirdPartyNotices`에 있고 앱 번들로 복사합니다. 정확히 대응하는 변경 없는 소스 압축 파일을 SHA-256과 함께 `sources/`에 포함합니다. 모든 구성 옵션과 빌드 단계는 `tools/build-media-tools.sh`에 있습니다. LumaView는 독립 도구의 수정·교체나 수정 디버깅에 필요한 역공학에 추가 제한을 두지 않습니다.

공식 출처:

- [FFmpeg 배포와 서명](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. 분리 서명은 FFmpeg 배포 키 `FCF986EA15E6E293A5644F10B4322F04D67658D8`로 검증했습니다.
- [dav1d 배포](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [FFmpeg 라이선스 정보](https://ffmpeg.org/legal.html).

## 재빌드

일반 앱 빌드는 동봉된 유니버설 바이너리를 사용합니다. 도구 재빌드에는 Xcode Command Line Tools, Python 3, Meson 1.12.1, Ninja 1.13.2를 설치합니다. 예를 들어 로컬 Python 가상 환경에 `meson==1.12.1 ninja==1.13.2`를 설치하고 활성화한 다음 실행합니다:

```sh
./tools/build-media-tools.sh
./build.sh
```

첫 명령은 소스 체크섬을 확인하고 두 아키텍처를 컴파일하여 `Resources/MediaTools/{ffmpeg,ffprobe}`를 교체합니다. `LUMAVIEW_PYTHON`으로 Python, `LUMAVIEW_MEDIA_BUILD`로 중간 빌드 폴더를 선택합니다. `x86_64` 또는 `arm64` 인수는 단일 아키텍처, 기본 `universal`은 둘을 합칩니다. 앱 빌드는 내장 도구와 앱에 로컬 ad-hoc 서명을 합니다.

네트워크, 캡처 장치, ffplay, dav1d 이외의 외부 코덱, GPL 인코더는 비활성화합니다. 이 구성에서 사용할 수 있는 모든 내부 디코더 / 디멀티플렉서를 포함합니다. 오디오 출력은 AAC로 준비합니다. 비디오는 가능하면 리먹스하고 이후 VideoToolbox H.264, MPEG-4 또는 ProRes 호환 출력으로 만듭니다. 보기 경로이며 내보내기나 트랜스코딩 UI는 아닙니다.

## PostScript 벡터 해석기

EPS, PostScript, 구형 Illustrator 미리 보기는 내장 Ghostscript 10.08.0을 별도의 제한된 로컬 자식 프로세스로 추가 사용합니다. AGPL-3.0-or-later 라이선스, 전체 대응 소스, 체크섬, 재현 가능한 유니버설 빌드는 [README-Ghostscript.md](README-Ghostscript.md)를 참고하세요. 일반 앱 빌드는 시스템 Ghostscript 설치가 필요 없습니다.
