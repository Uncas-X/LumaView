# Formats et aperçus

<!-- doc-navigation:start -->
[Documentation](INDEX.md) · [简体中文](../zh-Hans/FORMATS.md) · [繁體中文](../zh-Hant/FORMATS.md) · [English](../en/FORMATS.md) · [日本語](../ja/FORMATS.md) · [한국어](../ko/FORMATS.md) · **Français** · [Deutsch](../de/FORMATS.md) · [Español](../es/FORMATS.md) · [Italiano](../it/FORMATS.md) · [Português (Brasil)](../pt-BR/FORMATS.md) · [Русский](../ru/FORMATS.md) · [العربية](../ar/FORMATS.md) · [हिन्दी](../hi/FORMATS.md) · [Türkçe](../tr/FORMATS.md) · [Nederlands](../nl/FORMATS.md) · [Polski](../pl/FORMATS.md)
<!-- doc-navigation:end -->


Le catalogue de LumaView 1.7.2 contient 72 groupes d’images, vecteurs / documents, vidéos et fichiers audio. Il sert à découvrir les fichiers et choisir leur application par défaut ; ce n’est pas une liste de compatibilité intégralement testée. Une même extension peut contenir différents encodages ; l’ouverture dépend du contenu, des capacités du système et des décodeurs intégrés.

## Images

| Catégorie | Exemples de formats |
| --- | --- |
| Images courantes | JPEG, PNG / APNG, GIF, TIFF, BMP, HEIC / HEIF, WebP |
| Autres images | AVIF, JPEG XL, JPEG 2000, ICO / CUR / ICNS, PSD / PSB, TGA, HDR / OpenEXR, Netpbm |
| RAW d’appareils photo | DNG, Canon CR2 / CR3 / CRW, Nikon NEF / NRW, Sony ARW / SR2 / SRF, ainsi que ORF, RAF, RW2, PEF, SRW |

Les images sont décodées par macOS ImageIO. Le tableau énumère les candidats du catalogue ; la prise en charge des RAW, nouveaux encodages et formats professionnels varie particulièrement selon la version du système. Aucun décodeur RAW supplémentaire n’est intégré. GIF permet l’animation et TIFF la navigation multipage ; les autres formats composites sans pagination implémentée affichent seulement la première image.

Les zones transparentes des images matricielles PNG / APNG, GIF, PSD / PSB, etc. laissent uniformément apparaître le fond courant, sans damier gris et blanc. L’ombre suit l’opacité réelle des pixels, y compris les masques doux distincts et chaque image d’une animation, sans ombre rectangulaire ni bordure sur les marges vides du canevas. Cet effet concerne uniquement l’affichage : une copie conserve la transparence d’origine, sans ombre d’affichage. PDF, SVG et autres documents vectoriels suivent la règle du papier blanc décrite plus bas.

**Photoshop PSD / PSB :** lecture du composite enregistré dans le fichier pour l’image principale, les vignettes et la copie de l’image affichée ; aucune reconstruction ni édition des calques Photoshop. Si le fichier indique explicitement l’absence de composite compatible, un message invite à le réenregistrer dans Photoshop avec « Maximiser la compatibilité ». PSD / PSB correspondent aux versions de fichier 1 / 2 ; selon la [spécification Adobe](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/), un côté ne peut dépasser respectivement 30,000 / 300,000 pixels.

Le décodage a été validé sur 112 combinaisons de base : pour PSD et PSB, niveaux de gris à un canal ou avec canaux supplémentaires, RGB à trois canaux ou avec canaux supplémentaires en 8 / 16 / 32 bits, et CMYK en 8 / 16 bits ; chaque combinaison couvre sans compression, PackBits RLE, ZIP et ZIP prediction. S’y ajoutent 128 échantillons niveaux de gris/RGB avec véritables enregistrements de calques, distinguant alpha utilisateur et transparence du composite en 8 / 16 / 32 bits : nombres de calques positifs et négatifs, enregistrements globaux Lr16/Lr32, marqueurs de transparence et encodages sans compression/ZIP. Un PSB de 300,000 × 128 pixels valide aussi l’aperçu limité, l’image principale et les vignettes. Ces matrices sont générées d’après la spécification. La version 1.7.1 ajoute trois PSB réels d’environ 108–123 MiB, avec calques, composite transparent et ICC, pour tester image principale et vignettes ; ces contrôles ne valident pas tous les exports Photoshop possibles.

La bande de vignettes privilégie le JPEG RGB valide enregistré par Photoshop (ressource 1036), après contrôle de l’encodage, des dimensions, du rapport largeur/hauteur et de la longueur ; s’il manque, est corrompu ou non pris en charge, le composite est utilisé. L’aperçu incorporé, généralement petit, sert uniquement aux vignettes ; la zone principale lit toujours le composite compatible. Le RLE est lu par blocs d’au plus 64 KiB pour éviter une lecture de fichier par marqueur compressé ; les données traversant plusieurs blocs et les longues suites no-op restent annulables.

ZIP, RLE à grande profondeur, grandes images et fichiers à canaux supplémentaires utilisent une lecture de secours intégrée ligne par ligne, puis ImageIO interprète les couleurs. Un marqueur explicite de transparence du composite déclenche la lecture correspondante ; en RGB/niveaux de gris, le fond blanc du composite est retiré et un masque distinct ajouté. Sans déclaration de transparence, seules les couleurs de base sont affichées, sans confondre une sélection enregistrée avec la transparence. Les combinaisons de plusieurs alpha, tons directs, transparence CMYK et masques complexes ne sont pas entièrement validées et ne garantissent pas le même résultat que la composition des calques Photoshop. La lecture de secours conserve le premier profil ICC incorporé de 4 MiB maximum et le confie au système. Si celui-ci refuse un petit composite avec ICC valide, les pixels sont décodés séparément, puis le profil original validé et compatible avec le modèle et le nombre de composantes est réattaché, au lieu d’être abandonné. Les profils plus volumineux sont ignorés, avec une possible interprétation colorimétrique système par défaut. Les données 32 bits servent à l’aperçu, sans les contrôles complets de tonalité HDR de Photoshop. Lab, couleurs indexées, bichromie et autres modes spéciaux ne figurent pas dans la matrice ; leur lecture dépend de la structure et du système. Un contrôle natif distinct couvre un petit fichier PackBits 1 bit.

Une grande image n’est pas refusée au seul motif qu’elle dépasse 150 millions de pixels. Le chargeur adapte l’aperçu au budget mémoire, avec un grand côté d’au plus 8192 pixels et environ 32 millions de pixels au maximum, parfois moins. Le panneau d’informations conserve dimensions et orientation originales et signale le sous-échantillonnage. Le zoom est calculé sur les dimensions originales ; agrandir l’aperçu ne récupère pas les détails non décodés. Les fichiers endommagés ou indécodables produisent toujours une erreur.

## Vecteurs et documents

| Format | Comportement actuel |
| --- | --- |
| SVG | Dessin hors ligne par le moteur vectoriel système, mis à jour avec le zoom ; les déclarations DTD SVG standard reconnues sont autorisées sans chargement de DTD ; DTD personnalisées/internes, scripts, gestionnaires d’événements et ressources externes sont refusés. Certains SVG complexes ou dynamiques peuvent ne pas s’afficher. |
| PDF | Vignettes multipages, barre de progression, numéros de page, focus et navigation au clavier ; dessin au zoom courant, avec zone de rognage et orientation préservées ; aucune édition de document. |
| AI | Affichage direct des données compatibles PDF, avec plusieurs pages / plans de travail ; les anciens AI PostScript sont convertis en PDF vectoriel par Ghostscript intégré ; les fichiers contenant uniquement des données Illustrator propriétaires ne sont pas garantis lisibles. |
| EPS / PostScript | Ghostscript 10.08.0 intégré convertit tout le dessin en PDF en conservant tracés, texte et images incorporées, puis le canevas vectoriel l’affiche ; PS multipage pris en charge. Si l’interprétation échoue et qu’un DOS EPS contient un TIFF valide, un aperçu matriciel identifié peut servir de secours. Les images matricielles restent limitées par leur résolution et les polices indisponibles non incorporées peuvent être remplacées. |

Le canevas conserve les sources vectorielles PDF / SVG et dessine la zone visible par tuiles de 512 pixels au zoom courant, jusqu’à 3200%. Lors d’un changement de page, un fond de page complet adapté à l’écran est préparé en arrière-plan ; après la transition de la page entière, la couche vectorielle originale ajoute les détails au zoom courant, sans zones blanches apparaissant tuile par tuile. Le fond est limité à 4096 pixels sur le grand côté, sans réduire la netteté du vecteur agrandi. Le papier est blanc uni, sans damier ; les photos incorporées restent limitées par leur résolution. Chaque page TIFF utilise l’aperçu matriciel limité des grandes images. Un PDF chiffré non déverrouillé ne peut pas être consulté directement, aucun champ de mot de passe n’étant proposé. Le rendu ne réécrit pas l’original.

PDF / AI compatible PDF permet de copier par clic droit l’image matricielle incorporée pointée, ou toute la page. Les XObject courants, images en ligne, Form imbriqués, découpes et orientations sont pris en charge. Les masques et espaces colorimétriques complexes utilisent le rendu de la zone visible ; les structures particulières comme les images dans un Pattern ou les pages dépassant le budget d’analyse peuvent empêcher la copie individuelle. La sortie est une image PNG/TIFF d’au plus 8192 pixels sur le grand côté et d’environ 32 millions de pixels ; l’original reste inchangé.

## Vidéo et audio

| Catégorie | Exemples du catalogue |
| --- | --- |
| Conteneurs vidéo courants | MP4 / M4V, MOV, MKV, WebM, AVI, FLV, WMV / ASF, MPEG, TS / M2TS, 3GP |
| Autres vidéos et flux | OGV, RM / RMVB, VOB, MOD / TOD, Motion JPEG, MXF, DV, NUT, NSV, AMV, Bink / Smacker, ainsi que flux H.264, HEVC, VVC, IVF, Y4M |
| Audio courant | MP3, AAC, M4A, WAV, AIFF, CAF, FLAC, Ogg / Vorbis, Opus, WMA |
| Autres formats audio | Speex, APE, WavPack, TTA, TAK, Shorten, AC-3 / E-AC-3 / TrueHD, DTS, AMR, AU / SND, RealAudio, DSD, MKA, Musepack, GSM / QCP, IFF Audio |

La lecture par AVFoundation est tentée en premier. En cas d’échec, FFmpeg 9.0.2 / ffprobe fournis avec l’application prennent le relais, avec dav1d 1.5.3 lié statiquement pour AV1. Pour les vidéos admissibles, le conteneur est d’abord changé en conservant l’encodage vidéo ; si nécessaire ensuite, elles sont converties en encodage lisible par le système. L’audio peut également passer par cette préparation compatible.

La préparation est locale, avec fonctions réseau désactivées, sans installation supplémentaire. Elle doit traiter le fichier entier et ne garantit pas un démarrage immédiat. L’interface affiche la progression ; changer de fichier ou fermer la fenêtre annule l’opération. Le transcodage peut modifier la qualité visuelle, sonore ou colorimétrique, mais pas le fichier original. Les performances des hautes résolutions, fréquences élevées, encodages complexes et fichiers longs dépendent de l’appareil.

Le cache est automatiquement nettoyé avec un objectif de 2 GB ; les fichiers utilisés sont conservés, donc il ne s’agit pas d’un plafond absolu. Chaque fichier préparé est limité à 8 GB et au moins 512 MB doivent rester libres sur le disque ; un dépassement arrête la préparation avec une erreur. Un cache valide peut être réutilisé lors d’une nouvelle ouverture.

DRM, fichiers endommagés, décodeurs externes absents, encodages propriétaires et certains conteneurs particuliers peuvent empêcher la lecture. Les formats rares du catalogue ne sont pas tous garantis et chaque combinaison de codecs n’a pas été testée. Aucune gestion des sous-titres externes, menus de disques ou lecture en streaming n’est proposée.

## Pochettes et formes d’onde audio

La zone principale privilégie la pochette incorporée, obtenue d’abord par les métadonnées natives, puis si nécessaire par extraction de l’attached picture avec les outils intégrés. La pochette est décodée avec un grand côté de 2048 pixels ; une pochette illisible laisse place à la forme d’onde. Sans pochette incorporée, aucun téléchargement ni lecture de cover.jpg dans le dossier n’est effectué.

Sans pochette, une enveloppe des crêtes du morceau entier est calculée à partir des échantillons réellement décodés, avec au plus 4096 intervalles. Chaque tampon PCM est limité, sans chargement du morceau entier en mémoire, même pour un long fichier. Pour l’audio converti, la forme d’onde est calculée depuis le fichier de lecture local préparé. C’est une vue d’ensemble, pas un spectre en temps réel ; la lecture continue pendant le calcul. Changer de fichier ou fermer la fenêtre annule l’analyse, et un résultat tardif ne remplace pas le fichier courant. Les durées des vignettes sont lues séparément et de façon asynchrone, sans devoir sélectionner chaque fichier ; audio et vidéo affichent tous deux `▶ durée`.

## Application par défaut

Dans **LumaView → Application par défaut…** ou avec `⌘,`, cochez les groupes souhaités puis appliquez-les. Les associations système réelles sont relues à chaque ouverture, réactivation et fin de réglage ; elles persistent après redémarrage. Une coche indique que tous les types correspondent à cette application ; un tiret signale une correspondance partielle ou un autre exemplaire de LumaView. « Sélectionner tous les formats » couvre chaque catégorie indépendamment de la recherche ; la sélection globale d’un groupe ne concerne que sa catégorie. Les coches non appliquées constituent un brouillon et les effacer ne retire pas les associations déjà enregistrées. Le système peut considérer plusieurs extensions partageant le même identifiant comme un seul type ; elles changent alors ensemble.

L’interface relit les résultats du système et indique les formats en échec. Annuler arrête uniquement les modifications restantes, sans annuler celles déjà effectuées. Pour rétablir une application sur un format, choisissez-la dans « Lire les informations → Ouvrir avec → Tout modifier » du Finder.
