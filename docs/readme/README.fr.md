# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentation](../i18n/fr/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · **Français** · [Deutsch](../i18n/de/README.md) · [Español](../i18n/es/README.md) · [Italiano](../i18n/it/README.md) · [Português (Brasil)](../i18n/pt-BR/README.md) · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · [Türkçe](../i18n/tr/README.md) · [Nederlands](../i18n/nl/README.md) · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[Télécharger l’application macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versions et notes de mise à jour](https://github.com/Uncas-X/LumaView/releases)

Compatible avec macOS 13+ ; le même paquet prend en charge Intel et Apple Silicon. Décompressez le ZIP téléchargé et faites glisser `LumaView.app` dans « Applications » pour l’installer.

Visionneuse multimédia native pour macOS, inspirée des habitudes de consultation rapide de Picasa Photo Viewer : navigation dans un dossier, zoom, déplacement, rotation, bande de vignettes, plein écran et diaporama. La version 1.5 ajoute les pochettes et formes d’onde audio réelles, la navigation dans les documents multipages, un canevas vectoriel redessiné au niveau de zoom courant et des langues d’interface qui suivent le système par défaut. Son nom et son icône sont originaux ; elle ne prétend pas reproduire toutes les fonctions et interactions du Picasa historique.

La version 1.7.2 unifie l’affichage des zones transparentes : les images matricielles PNG, GIF, PSD / PSB, etc. laissent apparaître le fond de consultation ; l’ombre suit le contour et l’opacité de l’image, sans damier gris et blanc ni ombre rectangulaire entourant tout le canevas transparent. Les documents PDF conservent leur papier blanc.

Les optimisations PSD / PSB de la version 1.7.1 sont conservées : la bande de vignettes privilégie un JPEG incorporé valide, tandis que l’image principale décode toujours le véritable composite compatible. Le RLE est lu par blocs et le problème empêchant certaines petites images composites avec profil ICC de produire une vignette est corrigé.

## Utilisation et installation

Nécessite macOS 13 ou version ultérieure, sur Intel ou Apple Silicon.

1. Téléchargez `LumaView-macOS.zip` depuis [Releases](https://github.com/Uncas-X/LumaView/releases), décompressez-le, faites glisser `LumaView.app` dans « Applications », puis ouvrez-la.
2. Déposez des images, vidéos, fichiers audio ou dossiers, ou sélectionnez-les avec `⌘O`. L’ouverture d’un seul fichier affiche les médias du même dossier ; une sélection multiple limite la navigation aux fichiers choisis. Seul le niveau courant du dossier est parcouru, sans exploration récursive des sous-dossiers.
3. Dans le Finder, vous pouvez aussi effectuer un clic droit sur un fichier et choisir « Ouvrir avec → LumaView ».

Les compilations locales utilisent une signature ad hoc et ne sont pas notariées par Apple. Si Gatekeeper bloque la copie téléchargée sur un autre Mac, vérifiez sa provenance, puis utilisez l’option d’autorisation d’ouverture dans « Confidentialité et sécurité » du système.

## Application par défaut

Choisissez **LumaView → Application par défaut…**, appuyez sur `⌘,` ou ouvrez les réglages depuis « Plus ». Les formats sont regroupés en images, vecteurs / documents, vidéos et audio ; recherchez et cochez les formats souhaités, puis cliquez sur « Définir comme application par défaut pour les formats sélectionnés ». À chaque ouverture du panneau, réactivation de l’application et fin d’opération, les associations réelles du système sont relues : une coche indique que tous les types du groupe utilisent ce LumaView ; un tiret indique une association partielle ou un autre exemplaire de l’application. Les associations système persistent après redémarrage ; les sélections non appliquées ne sont pas présentées comme réussies. « Sélectionner tous les formats » couvre toutes les images, tous les documents vectoriels, toutes les vidéos et tous les fichiers audio, indépendamment de la recherche ; chaque catégorie possède aussi sa sélection globale. Effacer la sélection ne supprime pas les associations système existantes.

Le réglage affiche sa progression et relit chaque résultat du système. Annuler arrête les opérations suivantes mais conserve les modifications déjà effectuées. La liste représente les associations sélectionnables, sans garantir que chaque encodage interne ou fichier ait été testé ; consultez [Formats et aperçus](../i18n/fr/FORMATS.md).

## Consultation et lecture

À la première ouverture d’un fichier, la fenêtre occupe la zone disponible de l’écran courant ; `F` active le plein écran. La bande de vignettes inférieure permet de changer directement de fichier. La barre de commandes se masque après une période d’immobilité du pointeur sur l’image et réapparaît quand il bouge.

La version 1.5.2 corrige les vignettes vides ou clignotantes lors d’une navigation prolongée dans de grands dossiers : les vignettes visibles sont conservées séparément et les chargements hors écran sont annulés rapidement ; les anciens résultats ne sont plus insérés après un changement de dossier. Un fichier indécodable affiche un substitut stable ; revenir dans cette zone autorise une nouvelle tentative.

Images et vidéos permettent le zoom, le déplacement, la rotation et le plein écran. La fenêtre, les changements d’image, le zoom et la rotation utilisent de brèves transitions fluides, interrompables par les actions suivantes. L’option système « Réduire les animations » désactive ces transitions personnalisées ; les images animées continuent à jouer. Le fond par défaut est un verre dépoli translucide ; la barre d’espace alterne entre verre dépoli, fond sombre et fond clair.

La transparence des images matricielles suit une règle unique : le fond courant reste visible, l’ombre suit seulement les pixels contenant du contenu et les bords semi-transparents conservent leur opacité. L’ombre des GIF / APNG évolue à chaque image. Une copie préserve les pixels transparents d’origine, sans inclure le fond ou l’ombre de la visionneuse.

Les commandes audio et vidéo de lecture, arrêt, progression et volume se trouvent au-dessus de la bande de vignettes. La lecture démarre automatiquement et reste à la fin lorsqu’elle se termine ; `P` permet de rejouer et `S` arrête puis revient au début. Le bouton de diaporama inférieur est indépendant du bouton multimédia : après activation de la lecture continue par `⌘4`, les images changent à l’intervalle choisi, tandis que les médias audio et vidéo sont lus jusqu’au bout avant le fichier suivant. La lecture multimédia seule ne passe pas automatiquement au suivant.

La lecture native de macOS est privilégiée. Lorsqu’elle est impossible, FFmpeg 9.0.2 et dav1d 1.5.3 universels intégrés préparent un fichier compatible en local ; un changement de conteneur est tenté d’abord si possible, puis un transcodage. Aucun lecteur, Homebrew ou paquet de codecs supplémentaire n’est nécessaire, et aucun accès réseau n’est effectué. Il faut attendre la préparation du fichier complet, avec affichage de la progression ; changer de fichier ou fermer la fenêtre l’annule. La première préparation d’une longue vidéo peut demander beaucoup de temps et d’espace disque.

`C` ou le menu « Plus » règle la navigation en boucle, le comportement de la molette, la fermeture par le fond, la bande de vignettes, le tri et l’intervalle du diaporama (2, 3, 5, 8, 10 secondes). Par défaut, la molette zoome et `Ctrl` la transforme temporairement en navigation entre fichiers ; si la navigation est choisie par défaut, `Ctrl` active temporairement le zoom. « Cliquer sur le fond hors de l’image pour fermer » est activé par défaut. Ces préférences sont enregistrées localement.

## Menu contextuel et copie

Un clic droit (ou Ctrl-clic) sur la zone principale propose « Ouvrir avec → Application / Autre application… » et « Afficher dans le Finder ». « Ouvrir avec » s’applique seulement à cette ouverture, sans modifier l’association par défaut ; ces deux options restent disponibles pour les fichiers indécodables.

- Images : « Copier l’image » conserve la rotation courante et les pixels transparents. La totalité de l’image actuellement décodée est copiée, sans barre d’outils ni recadrage sur la zone visible après zoom.
- Vidéos : « Copier l’image courante » copie l’image correspondant à l’ouverture du menu contextuel, avec l’orientation de la vidéo et la rotation de la vue, sans changer la position ni l’état de lecture.
- PDF / AI compatible PDF : un clic droit sur une image matricielle de la page permet « Copier cette image » ou « Copier la page courante ». La position réelle du clic est respectée après zoom, déplacement et rotation. Le texte ordinaire et les zones vectorielles ne sont pas considérés comme des images ; les masques ou espaces colorimétriques complexes copient l’apparence visible de la zone, qui peut inclure du texte superposé. Une page constituée d’une seule image numérisée est copiée comme une numérisation entière.
- `⌘C` copie l’image, l’image vidéo ou la page de document courante ; l’audio ne propose pas de copie d’image. Le presse-papiers reçoit PNG et TIFF ; après changement de fichier / page ou fermeture, un résultat de copie périmé ne l’écrase pas.

La copie de documents et d’images incorporées produit une image matricielle d’au plus 8192 pixels sur le grand côté et d’environ 32 millions de pixels, sans instructions vectorielles PDF/SVG dans le presse-papiers. Pour une grande image affichée sous forme d’aperçu limité, c’est cet aperçu qui est copié. L’analyse des images PDF possède une limite de complexité ; certaines structures, telles que les images dans des motifs de remplissage, ne sont pas sélectionnables individuellement, mais la page entière reste copiable.

Les en-têtes SVG 1.0/1.1 standard sont analysés hors ligne, sans charger de DTD externe. La version 1.7 intègre Ghostscript 10.08.0 pour convertir EPS / PostScript et anciens AI PostScript en PDF conservant tracés, texte et images incorporées ; la zone principale redessine les vecteurs au niveau de zoom courant. Les PS multipages utilisent la navigation existante. Aucune installation supplémentaire n’est nécessaire. Si la conversion échoue mais qu’un EPS contient un TIFF incorporé valide, un aperçu de secours clairement étiqueté TIFF reste possible. Les images matricielles du fichier original ne deviennent pas vectorielles.

## Audio, documents et langues

La zone principale privilégie la pochette incorporée au fichier audio ; sans pochette utilisable, les échantillons réels sont analysés de façon asynchrone pour afficher la forme d’onde du morceau entier. Un substitut apparaît pendant l’analyse, sans retarder la lecture. Les vignettes audio et vidéo affichent toutes `▶ durée` en bas à droite, avec les mêmes police, fond et position ; avant lecture de la durée, elles affichent `▶ –:––`. La pochette provient des métadonnées incorporées, sans recherche sur le réseau ou dans le dossier.

PDF, AI compatibles PDF et TIFF multipages permettent la navigation interne. Les petites vignettes de pages, la barre de progression et le compteur page courante / total se trouvent au-dessus de la bande des fichiers. `↑` donne le focus aux pages et `↓` aux fichiers ; une bordure orange indique la sélection de la rangée active, tandis qu’une bordure grise conserve la sélection de l’autre rangée, sans étiquettes « Pages / Fichiers ». `←` / `→`, `J` / `K` et `Home` / `End` agissent sur le focus courant. Cliquer dans une rangée lui donne aussi le focus. La navigation s’arrête à la première ou dernière page sans passer involontairement à un autre fichier. Les boutons inférieur précédent / suivant changent toujours de fichier. La navigation interne subsiste lorsque la bande des fichiers est masquée.

PDF, SVG et AI compatibles PDF dessinent la zone visible à partir des instructions vectorielles originales au zoom courant, au lieu d’agrandir un aperçu fixe. Les zones transparentes des documents utilisent du papier blanc uni, sans damier. Au changement de page, une transition en fondu de la page entière attend que celle-ci soit prête ; le dessin des détails vectoriels en arrière-plan ne laisse plus apparaître des blancs tuile par tuile. Les photos et autres images matricielles incorporées restent limitées par leur résolution d’origine.

Choisissez **LumaView → Langue…** ou utilisez « Plus ». Le système est suivi par défaut ; chinois simplifié, chinois traditionnel, anglais, japonais, coréen, français, allemand, espagnol, italien, portugais, russe, arabe, hindi, turc, néerlandais et polonais sont disponibles. Menus, info-bulles, pagination et réglages se mettent immédiatement à jour, et le choix est mémorisé localement. Une langue système non prise en charge utilise l’anglais ; certaines erreurs rares de décodage peuvent également rester en anglais. Noms de fichiers, chemins et texte contenu dans les fichiers restent inchangés.

## Clavier et souris

| Action | Raccourci / geste |
| --- | --- |
| Élément précédent / suivant (selon le focus) | `←` / `→`, ou `J` / `K` |
| Focus pages / fichiers | `↑` / `↓` (documents multipages) |
| Premier / dernier élément | `Home` / `End` |
| Ouvrir des fichiers ou un dossier | `⌘O` |
| Application par défaut | `⌘,` |
| Zoom | Molette, pincement du trackpad, `+` / `−`, `Page Up` / `Page Down` |
| Inverser temporairement la molette | Faire défiler en maintenant `Ctrl` |
| 100% / Ajuster à la fenêtre | Cliquer sur l’image, ou `1` |
| Ajuster à la fenêtre | `0` |
| Déplacer une image ou vidéo agrandie | Faire glisser l’image |
| Rotation horaire de la vue | `⌘R` / `Ctrl+R`, avec `Shift` pour le sens antihoraire |
| Changer de fond | Espace |
| Activer / quitter le plein écran | `F` / `⌃⌘F` / `F11` (si le système ne les utilise pas) |
| Lire / mettre en pause l’audio ou la vidéo | `P` |
| Arrêter l’audio ou la vidéo et revenir au début | `S` |
| Démarrer / arrêter le diaporama et la lecture continue | `⌘4` |
| Reculer / avancer l’audio ou la vidéo de 5 secondes | `Option + ←` / `Option + →` |
| Couper / rétablir le son | `M` |
| Informations sur le fichier | `I` / `⌘I` |
| Afficher / masquer la bande de vignettes | `T` / `⌘T` |
| Options supplémentaires | `C` |
| Afficher le fichier courant dans le Finder | `⌘Return` |
| Mettre en pause, fermer les informations, quitter le plein écran, fermer la fenêtre | `Esc`, dans cet ordre selon l’état courant |
| Réduire / fermer / quitter | `⌘M` / `⌘W` / `⌘Q` |

`P` contrôle uniquement le média audio ou vidéo courant, jamais le diaporama d’images. « Aide → Clavier et souris » fournit aussi des instructions intégrées.

## Prise en charge et limites

- Les images sont décodées par ImageIO ; la prise en charge réelle de JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW, etc. dépend du système et du contenu du fichier.
- Une image n’est plus rejetée simplement parce qu’elle dépasse 150 millions de pixels. Pour limiter la mémoire, un aperçu sous-échantillonné est généré si nécessaire, en conservant dimensions et orientation d’origine ; le zoom à 100% utilise ces dimensions, mais ne restitue pas les détails non décodés.
- Affichage vectoriel de SVG, PDF, AI compatibles PDF, ainsi que EPS / PS / anciens AI traités par l’interpréteur intégré. PDF / AI / PS multipages permettent de tourner les pages ; SVG refuse scripts et ressources externes. Les images matricielles incorporées restent limitées par leur résolution ; une police non incorporée et indisponible peut être remplacée.
- PostScript s’exécute dans un processus distinct avec SAFER et le bac à sable système : seuls les fichiers temporaires d’entrée et de sortie courants sont autorisés, sans réseau. Un changement rapide de fichier permet l’annulation ; vignette et image principale partagent le cache des conversions terminées. Une interprétation est limitée à 90 secondes, la sortie à 1 GB et l’objectif de nettoyage du cache est de 2 GB.
- Photoshop PSD / PSB affiche le composite enregistré, sans édition de calques. Un immense canevas produit un aperçu respectant le budget mémoire tout en conservant ses dimensions originales ; voir FORMATS.md pour les modes de couleur, profondeurs et compressions.
- Le décodage compatible intégré élargit les formats audio et vidéo, mais DRM, fichiers endommagés et encodages propriétaires sans décodeur peuvent rester illisibles. Une extension ne garantit pas le décodage interne ; tous les formats, appareils et systèmes n’ont pas été testés individuellement.
- Le nettoyage du cache de compatibilité vise 2 GB ; les fichiers en cours d’utilisation peuvent temporairement dépasser cet objectif. Chaque fichier préparé est limité à 8 GB, avec au moins 512 MB d’espace disque libre conservé. Un manque d’espace arrête la préparation et affiche un message.
- TIFF permet la navigation multipage ; les autres formats d’image composites sans pagination implémentée affichent seulement leur première image. La rotation d’affichage ne modifie pas le fichier. Aucune édition, suppression, base de photothèque, fonction de partage, synchronisation cloud ou gestion de sous-titres externes n’est proposée.
- Seuls les médias locaux ouverts par l’utilisateur et leur dossier sont lus ; la lecture compatible écrit dans le cache local, sans téléverser les médias ni modifier les originaux.

D’autres exemples de formats et les limites des aperçus et du cache figurent dans [FORMATS.md](../i18n/fr/FORMATS.md).

## Compiler depuis les sources

Nécessite Xcode ou les Command Line Tools comprenant Swift. Le dépôt et le paquet source contiennent les outils multimédias universels Intel / Apple Silicon ; une compilation normale ne nécessite aucun téléchargement ni installation supplémentaire de dépendances tierces. Après clonage ou téléchargement, placez-vous à la racine contenant `build.sh` ; l’arborescence du poste de développement original n’est pas nécessaire.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

La compilation produit une application universelle par défaut ; `./build.sh --host` cible seulement l’architecture du Mac courant. L’application se trouve par défaut à côté du dossier source sous `LumaView.app` ; `LUMAVIEW_APP_PATH` permet un autre emplacement. Les fichiers de travail de compilation et de tests vont dans `.build/` du dépôt, remplaçable par `LUMAVIEW_WORK_ROOT` ; `.gitignore` exclut ces fichiers générés.

`LUMAVIEW_TEST_BUILD=1 ./build.sh --host` produit une application distincte `LumaView Tests`, sans déclarations d’ouverture de fichiers, pour éviter que la copie de test ne supplante l’installation normale. Les scripts d’interface utilisent ce mode par défaut ; `LUMAVIEW_SKIP_TEST_BUILD=1` et `LUMAVIEW_TEST_APP_PATH` permettent de désigner une application déjà compilée.

FFmpeg est compilé sous LGPL 2.1 ou ultérieure ; dav1d, lié statiquement, utilise BSD 2-Clause. Archives sources correspondantes, sommes de contrôle et licences accompagnent le paquet source. Pour reconstruire les outils multimédias, installez Xcode Command Line Tools, Python 3, Meson 1.12.1 et Ninja 1.13.2, éventuellement dans un environnement virtuel Python, puis lancez `./tools/build-media-tools.sh`. Les étapes et options figurent dans [ThirdParty/README.md](../i18n/fr/ThirdParty/README.md). PostScript utilise Ghostscript 10.08.0 distinct (AGPL-3.0-or-later), avec licence, sources correspondantes complètes et script de compilation. La compilation normale utilise le composant à deux architectures fourni ; consultez les [instructions Ghostscript](../i18n/fr/ThirdParty/README-Ghostscript.md) pour le reconstruire.

## Sources et validation

- `Sources/` : interface AppKit, canevas multimédia, chargement d’images et de vecteurs, cycle de vie audio et vidéo, préparation compatible et applications par défaut.
- `Resources/Localizations/` : textes traduits et liste des clés de traduction essentielles.
- `Resources/MediaFormats.json` : catalogue des formats ; `Resources/MediaTools/` : FFmpeg / ffprobe intégrés.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/` : sources correspondantes et licences des outils multimédias.
- `build.sh` : compilation universelle, empaquetage et signature locale ; `tools/build-media-tools.sh` : reconstruction des outils multimédias.

```bash
./Tests/run-core-tests.sh
./Tests/run-thumbnail-tests.sh
./Tests/run-thumbnail-request-tests.sh
./Tests/run-canvas-tests.sh
./Tests/run-ui-tests.sh
./Tests/run-video-tests.sh
./Tests/run-default-application-tests.sh
./Tests/run-default-preferences-tests.sh
./Tests/run-media-declaration-tests.sh
./Tests/run-document-tests.sh
./Tests/run-vector-compatibility-tests.sh
./Tests/run-postscript-tests.sh
./Tests/run-photoshop-tests.sh
./Tests/run-pdf-image-copy-tests.sh
./Tests/run-media-copy-tests.sh
./Tests/run-context-menu-tests.sh
./Tests/run-large-document-tests.sh
./Tests/run-audio-waveform-tests.sh
./Tests/run-audio-visual-tests.sh
./Tests/run-localization-tests.sh
```

Les tests unitaires de décodage audio construisent des échantillons MP3 / FLAC / Opus et nécessitent un FFmpeg de développement doté des encodeurs correspondants, indiqué par `LUMAVIEW_TEST_FFMPEG`. L’application et les tests d’interface audio utilisent uniquement les composants fournis.

Les contrôles d’intégration de l’interface nécessitent une session graphique macOS ouverte ; ils lancent l’application et vérifient les interactions avec des médias générés automatiquement. Fichiers de compilation et rapports vont par défaut dans `.build/`, certains médias temporaires dans le dossier temporaire système ; les tests ne lisent pas les photos personnelles par défaut. Les tests de copie utilisent un presse-papiers nommé distinct, sans remplacer le contenu courant ; les tests Ouvrir avec / Finder / application par défaut utilisent des interfaces simulées et ne modifient pas les associations. Voir [TEST-RESULTS.txt](../i18n/fr/TEST-RESULTS.md) pour la validation de la version livrée.

Les rapports conservés dans `Tests/` relatent des validations historiques de leurs versions, sans garantir que votre environnement après clonage ait déjà passé les tests. Les noms d’échantillons personnels sont anonymisés et leurs médias originaux ne sont pas inclus. Les chemins historiques `work/` indiquent l’origine des tests à l’époque, sans être requis aujourd’hui. Les archives sources, sommes de contrôle et licences des outils tiers conservées dans le dépôt rendent le premier clonage volumineux.
