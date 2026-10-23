# LumaView इंटरफ़ेस भाषाएँ

<!-- doc-navigation:start -->
[दस्तावेज़ सूची](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · **हिन्दी** · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


ऐप **फ़ॉलो सिस्टम** से शुरू होता है। यह macOS की पसंदीदा भाषा सूची में पहली समर्थित भाषा चुनता है, फिर यदि कोई समर्थित नहीं है तो अंग्रेजी चुनता है। **LumaView → भाषा...** में चयनित भाषा तुरंत प्रभावी होती है और केवल इस ऐप के लिए याद रखी जाती है।

समर्थित विकल्प: सरलीकृत चीनी, पारंपरिक चीनी, अंग्रेजी, जापानी, कोरियाई, फ्रेंच, जर्मन, स्पेनिश, इतालवी, पुर्तगाली, रूसी, अरबी, हिंदी, तुर्की, डच और पोलिश। पुर्तगाली संस्करण वर्तमान में ब्राज़ीलियाई पुर्तगाली कैटलॉग का उपयोग करते हैं। पिकर में मूल नाम जानबूझकर हैं, ताकि उपयोगकर्ता किसी अपरिचित इंटरफ़ेस भाषा से उबर सके।

`catalog.json` स्थानीयकृत स्ट्रिंग्स के लिए पठनीय सरलीकृत चीनी स्रोत कुंजियों को मैप करता है। `core-keys.json` प्रत्येक कैटलॉग में आवश्यक सामान्य नियंत्रण, मेनू, सेटिंग्स, दस्तावेज़ नेविगेशन, मेटाडेटा लेबल और कीबोर्ड-सहायता स्ट्रिंग को परिभाषित करता है। जब किसी भाषा की अपनी प्रविष्टि नहीं होती है तो कम-आवृत्ति डायग्नोस्टिक संदेश अंग्रेजी फ़ॉलबैक का उपयोग करते हैं। फ़ाइलों, निर्देशिकाओं, कोडेक्स, प्रारूपों और एम्बेडेड कैमरा मेटाडेटा के नाम अपरिवर्तित रहते हैं। ओएस अपनी भाषा में मूल सिस्टम संवाद पाठ की आपूर्ति करता है।

स्थिर पाठ के लिए `L10n.tr("source key")` का उपयोग करें। गतिशील पाठ के लिए, अनुवाद से पहले एक चीनी स्ट्रिंग को प्रक्षेपित करने के बजाय `L10n.format("第 %d / %d 页", current, total)` का उपयोग करें। सभी अनुवादों में प्लेसहोल्डर प्रकार और गिनती को एक समान रखें। मौजूदा इंटरफ़ेस को ताज़ा करने और रेंडर किए गए टेक्स्ट को दोबारा बनाने के लिए `L10n.languageDidChange` का निरीक्षण करें। उपयोगकर्ता की निरंतर भाषा को संशोधित करने से बचने के लिए परीक्षण `useLanguageForTesting` का उपयोग करते हैं।

स्थानीय रिज़ॉल्यूशन, पूर्ण कोर कवरेज, प्रारूप-प्लेसहोल्डर स्थिरता, फ़ॉलबैक व्यवहार और अरबी पाठ दिशा के लिए `Tests/run-localization-tests.sh` चलाएँ। अनुवादित पाठ की व्यावसायिक भाषाई समीक्षा नहीं हुई है।
