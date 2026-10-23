# घोस्टस्क्रिप्ट दस्तावेज़ रूपांतरण उपकरण

<!-- doc-navigation:start -->
[दस्तावेज़ सूची](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · **हिन्दी** · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView, EPS और पोस्टस्क्रिप्ट को अस्थायी PDF में परिवर्तित करने के लिए एक अलग स्थानीय निष्पादन योग्य के रूप में, Artifex द्वारा 2026-09-08 पर जारी किए गए घोस्टस्क्रिप्ट **10.08.0** को आमंत्रित करता है। PDF आउटपुट समर्थित वेक्टर पथ, टेक्स्ट और ग्रेडिएंट्स को बरकरार रखता है। रेखापुंज पिक्सेल के रूप में पहले से ही एम्बेड की गई छवियाँ रेखापुंज छवियाँ ही बनी रहती हैं। घोस्टस्क्रिप्ट स्विफ्ट एप्लिकेशन से लिंक नहीं है, और इस बंडल निष्पादन योग्य को चलाने के लिए किसी होमब्रू इंस्टॉलेशन की आवश्यकता नहीं है।

## लाइसेंस और संबंधित स्रोत

घोस्टस्क्रिप्ट को **जीएनयू एफ़ेरो जनरल पब्लिक लाइसेंस संस्करण 3 या बाद के संस्करण** के तहत वितरित किया जाता है, जैसा कि इस रिलीज़ में मूल `LICENSE` फ़ाइल द्वारा निर्दिष्ट किया गया है। संपूर्ण लाइसेंस, घोस्टस्क्रिप्ट कॉपीराइट नोटिस, फ़ॉन्ट एम्बेडिंग अपवाद, एडोब सीएमएपी नोटिस और शामिल निर्भरता नोटिस को `Resources/ThirdPartyNotices/Ghostscript/` में बदलाव किए बिना कॉपी किया गया है। Artifex से एक अलग वाणिज्यिक लाइसेंस भी उपलब्ध है; इस पैकेज में वाणिज्यिक लाइसेंस शामिल नहीं है। [आधिकारिक लाइसेंसिंग पृष्ठ](https://www.ghostscript.com/licensing/index.html) देखें।

बंडल निर्भरता और फ़ॉन्ट स्रोतों सहित सटीक, असंशोधित संगत स्रोत रिलीज़, `ThirdParty/sources/ghostscript-10.08.0.tar.xz` पर शामिल है। इसका SHA-256 `ThirdParty/sources/SHA256SUMS-Ghostscript` में दर्ज है:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

स्रोत उद्गम: [आधिकारिक रिलीज़ पृष्ठ](https://www.ghostscript.com/releases/index.html) और [आर्टिफ़ेक्स की 10.08.0 रिलीज़ संपत्ति](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080)। चेकसम `.tar.xz` संपत्ति के लिए प्रकाशित चेकसम से मेल खाता है। स्रोत पैकेज और यह बिल्ड स्क्रिप्ट LumaView स्रोत वितरण के साथ आती है। LumaView इस अलग टूल के संशोधन या प्रतिस्थापन, या ऐसे संशोधनों को डीबग करने के लिए आवश्यक रिवर्स इंजीनियरिंग पर कोई अतिरिक्त प्रतिबंध नहीं लगाता है। ये नोटिस बंडल किए गए तृतीय-पक्ष घटक का वर्णन करते हैं; उनका उद्देश्य एप्लिकेशन के स्रोत को पुनः लाइसेंस देना नहीं है।

## पुनर्निर्माण

आवश्यकताएँ: macOS, Xcode कमांड लाइन टूल्स, सम्मिलित स्रोत संग्रह, और मानक macOS बिल्ड टूल्स। किसी होमब्रू लाइब्रेरी का उपयोग नहीं किया जाता है। LumaView स्रोत निर्देशिका से:

```sh
./tools/build-document-tools.sh
./build.sh
```

स्क्रिप्ट स्रोत संग्रह को सत्यापित करती है, अलग-अलग स्रोत निर्देशिकाओं से Intel और Apple सिलिकॉन स्लाइस बनाती है, स्थानीय प्रतीकों को हटाती है और स्लाइस को `Resources/DocumentTools/gs` में जोड़ती है। दोनों स्लाइस macOS 13.0 या बाद के संस्करण को लक्षित करते हैं। यह `make install` नहीं चलाता या सिस्टम पैकेज मैनेजर को नहीं लिखता। `LUMAVIEW_DOCUMENT_BUILD` इंटरमीडिएट बिल्ड निर्देशिका का चयन करता है; `LUMAVIEW_DOCUMENT_JOBS` make के समानांतर कार्यों की संख्या नियंत्रित करता है (डिफ़ॉल्ट 4)। वैकल्पिक तर्क `x86_64` या `arm64` केवल एक आर्किटेक्चर बनाता है। एप्लिकेशन बिल्ड ऐप के साथ कॉपी किए गए निष्पादन योग्य पर हस्ताक्षर करता है।

निष्पादन योग्य में इसके आंतरिक `%rom%` फ़ाइल सिस्टम में आरंभीकरण कोड, बंडल फ़ॉन्ट, Adobe CMaps और ICC प्रोफ़ाइल शामिल हैं। बाहरी डिफ़ॉल्ट खोज पथ खाली हैं. केवल `pdfwrite` आउटपुट डिवाइस सक्षम है। प्रिंटिंग/CUPS, X11, GTK, फॉन्टकॉन्फ़िग, D-Bus, Tesseract/OCR, डायनेमिक ड्राइवर, बाहरी IJS और दस्तावेज़ निष्कर्षण उपकरण अक्षम हैं। सभी शामिल डिकोडर/रंग/फ़ॉन्ट लाइब्रेरी संबंधित स्रोत संग्रह से संकलित की गई हैं; डायनेमिक लिंकेज Apple सिस्टम लाइब्रेरीज़ तक सीमित है। ROM फ़ाइल सिस्टम और क्रॉस-संकलन तंत्र के लिए [आधिकारिक बिल्ड दस्तावेज़](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) देखें।

LumaView दुभाषिया को `-dSAFER`, एक विशिष्ट इनपुट और आउटपुट फ़ाइल, एक निजी अस्थायी कार्यशील निर्देशिका, रद्दीकरण और एक टाइमआउट के साथ चलाता है। प्रक्रिया वातावरण को उपयोगकर्ता द्वारा निर्दिष्ट घोस्टस्क्रिप्ट विकल्प या लाइब्रेरी पथ विरासत में नहीं मिलने चाहिए। जनरेट किए गए विश्वसनीय परीक्षण फिक्स्चर का उदाहरण:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

पूरे बिल्ड विकल्प `tools/build-document-tools.sh` में हैं; स्रोत संग्रह में कोई पैच नहीं लगाया गया है. मूल निष्पादन का परीक्षण केवल बिल्ड होस्ट द्वारा समर्थित आर्किटेक्चर के लिए किया जा सकता है। रिलीज़ चेक दोनों मच-ओ स्लाइस का निरीक्षण करते हैं और होस्ट-संगत स्लाइस के माध्यम से पथ और टेक्स्ट युक्त एक जेनरेटेड ईपीएस चलाते हैं, जिससे पुष्टि होती है कि आउटपुट PDF में अभी भी वेक्टर ड्राइंग और टेक्स्ट ऑपरेटर शामिल हैं।
