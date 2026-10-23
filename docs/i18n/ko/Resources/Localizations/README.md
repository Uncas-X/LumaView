# LumaView 인터페이스 언어

<!-- doc-navigation:start -->
[문서 목록](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · **한국어** · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


앱의 초기 설정은 **시스템 따르기**입니다. macOS 선호 언어 목록에서 첫 지원 언어를 선택하고 없으면 영어를 씁니다. **LumaView → 언어…**에서 선택한 언어는 즉시 적용되며 이 앱에만 저장됩니다.

지원 언어: 중국어 간체·번체, 영어, 일본어, 한국어, 프랑스어, 독일어, 스페인어, 이탈리아어, 포르투갈어, 러시아어, 아랍어, 힌디어, 튀르키예어, 네덜란드어, 폴란드어. 포르투갈어 변종은 현재 브라질 포르투갈어 카탈로그를 사용합니다. 낯선 언어로 바뀌었을 때 돌아올 수 있도록 선택기는 의도적으로 각 언어의 고유 이름을 표시합니다.

`catalog.json`은 읽을 수 있는 중국어 간체 소스 키를 번역 문자열로 연결합니다. `core-keys.json`은 모든 카탈로그에 필요한 공통 컨트롤, 메뉴, 설정, 문서 탐색, 메타데이터 라벨, 키보드 도움말을 정의합니다. 드문 진단 메시지는 번역 항목이 없으면 영어를 씁니다. 파일, 폴더, 코덱, 형식, 내장 카메라 메타데이터 이름은 바꾸지 않습니다. 시스템 대화상자는 OS 자체 언어로 표시됩니다.

정적 텍스트는 `L10n.tr("source key")`를 사용합니다. 동적 텍스트는 먼저 중국어 문자열을 보간하지 말고 `L10n.format("第 %d / %d 页", current, total)`을 사용합니다. 번역 간 자리표시자의 형식과 개수를 맞춥니다. `L10n.languageDidChange`를 관찰해 기존 UI와 렌더링 텍스트를 갱신합니다. 테스트는 사용자의 저장 언어를 바꾸지 않도록 `useLanguageForTesting`을 씁니다.

`Tests/run-localization-tests.sh`로 로케일 결정, 전체 필수 키, 형식 자리표시자 일치, 대체 동작, 아랍어 방향을 검사합니다. 번역은 전문 언어 검수를 받지 않았습니다.
