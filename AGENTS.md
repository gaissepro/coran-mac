# Coran — app macOS native (Swift/SwiftUI) · notes pour les contributeurs

App gratuite : Coran (arabe + français Hamidullah) et hadiths (40 Nawawi, 40 Qudsi). Local, gratuite, sans compte Apple.
Interface inspirée de Rasmic (github.com/michaelshimeles/bible, MIT) : fond #0a0a0b, cartes en verre, Literata + Inter, thèmes sombre/sépia/clair.

## Build
`./build.sh` → `build/Coran.app` (swiftc direct : SwiftPM est cassé dans les Command Line Tools). Lancer : `open build/Coran.app`.

## Décisions
- Swift natif et pas Rust/egui : egui n'a pas de bidi RTL (epaint 0.37, TODO), donc l'arabe serait faux. Core Text gère RTL + tashkeel.
- Versets arabes entourés de U+2067…U+2069 : sinon SwiftUI traite le paragraphe en LTR et le numéro ﴿١﴾ se retrouve au début.
- Police arabe : Amiri Quran (OFL). Fonts dans Fonts/, copiées dans l'app.
- Scroll vers un verset : 3 tentatives (immédiat, 0,25 s, 0,7 s) car LazyVStack ignore les hauteurs réelles.

## Données
- Data/quran.json : API alquran.cloud (quran-uthmani + fr.hamidullah), format compact {n, ar, en, tr, type, ayahs[{n, ar, fr, j, p}]}.
- Data/hadith.json : fawazahmed0/hadith-api (ara/fra nawawi, qudsi). Bukhari et Muslim existent dans la même API (fra + ara) si on veut les ajouter.

## Test sans écran
`open --env CORAN_SNAPSHOT=<dossier> --env CORAN_SURAH=2 --env CORAN_AYAH=255 [--env CORAN_THEME=sepia] [--env CORAN_BOOK=nawawi --env CORAN_HADITH_N=1] build/Coran.app` → reader.png + palette.png.

## Raccourcis
⌘K recherche · ⌘+ / ⌘- taille arabe · ⇧⌘L thème · ⌘T traduction · ⌘] / ⌘[ sourate suivante/précédente.

## Gamification et apprentissage (v0.2)
- Inscription au premier lancement (prénom, niveau, objectif XP, couleur, thème). Page Paramètres via le profil en bas de la barre latérale.
- XP, niveaux, série de jours, objectif quotidien (anneau), 9 badges, confettis, sons système (NSSound) et voix arabe Majed (AVSpeechSynthesizer ar-001).
- « J'ai lu +5 XP » sous chaque verset/hadith ; sourate finie = +25 XP.
- Onglet « Arabe » : 4 unités (alphabet 6 leçons, voyelles, 40 mots du Coran, remise en ordre des versets de 6 courtes sourates). Code : Lessons.swift (contenu), LearnViews.swift (parcours + leçon), Gamify.swift (XP, sons, badges), Onboarding.swift (inscription + paramètres).
- Profil sauvegardé en JSON dans UserDefaults (clé profile.v1). Mode test : CORAN_DEMO=1 CORAN_MODE=learn CORAN_LESSON=alpha3 CORAN_SETTINGS=1 CORAN_ONBOARD=1 (rien n'est sauvegardé quand CORAN_SNAPSHOT est défini).

## Récitation, micro, révision (v0.3)
- Reciter.swift : récitation verset par verset (everyayah.com, 5 récitants, cache dans ~/Library/Caches/Coran/audio). Suivi du texte : verset surligné + mots colorés au prorata de la durée (pas de timing mot à mot réel). Barre de lecture : précédent/suivant, répéter le verset, vitesse, changer de récitant.
- Listener.swift : « Je récite » (micro sur un verset) et exercices « Lire à voix haute » : SFSpeechRecognizer ar-SA (serveurs Apple) puis comparaison mot à mot (Compare.match, seuil de similarité 0,66). Vérifie les mots, pas le tajwid. Info.plist : NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription (build.sh).
- Révision du jour : chaque question lettre/mot a une clé (L:ب / W:كِتَاب), les erreurs sont comptées dans UserDefaults miss.v1 ; la révision reprend en priorité les éléments fragiles.
- Test : CORAN_PLAY=1:2 CORAN_CHECK=1:2 CORAN_LESSON=read1 CORAN_DELAY=4 (son coupé en mode snapshot).
- NON TESTÉ en réel : permissions micro et reconnaissance (impossible à valider sans interaction humaine).

## Contexte, glossaire, stats (v0.4)
- En-tête de sourate (Context.swift) : nom arabe + français (Quran.com), nb de versets, Mecquoise/Médinoise, ordre de révélation, carte « Contexte de révélation » (Data/context.json, 114 résumés rédigés à la main, repères traditionnels).
- Notes par verset : 570 notes de la traduction française Montada (QuranEnc, Data/extra.json) via le bouton ⓘ ; choix de traduction Hamidullah/Montada (Réglages ou en-tête).
- Mots expliqués : Data/glossary.json (≈40 entrées dont 4:34, 9:5, 2:191, 24:31). Chips « Mots expliqués » sous le verset, tooltip au survol, clic = panneau. Matching dans Models.swift (Glossary), normalisation arabe dans Compare.norm.
- Stats (⎘ icône barres dans le profil) : temps passé par activité (lecture/écoute/leçons, app au premier plan), semaine, régularité 12 semaines, versets lus, précision des exercices. Stocké dans UserDefaults time.v1 / quiz.v1.
- Couleurs d'accent pastel (menthe, pêche, lavande, rose, ciel, citron). Bouton « Reprendre » et ✓ sur les sourates terminées.
- À vérifier : le contenu de context.json et glossary.json est rédigé par l'IA, à relire avec un savant ; les notes Montada reflètent le point de vue de leurs auteurs.

## Logo et installation
- Icon/make_icon.swift dessine le logo (ق mentholé + croissant pêche sur fond vert sombre) → icon_1024.png → AppIcon.icns (iconutil), copié par build.sh.
- Installée dans /Applications/Coran.app (ditto depuis build/) et épinglée au Dock via defaults com.apple.dock persistent-apps. Après chaque build : `ditto build/Coran.app /Applications/Coran.app`.

## Vidéo de présentation
- L'app sait se filmer : `CORAN_FILM=<dossier>` joue un scénario minuté (récitation, ⌘K, contexte, leçon, stats, thèmes) et attend le fichier `<dossier>/go` pour démarrer ; elle écrit `t0.txt` et `events.txt` (heure réelle de chaque scène). L'enregistrement se fait avec `screencapture -v -o -l<id fenêtre>` (autorisation Enregistrement de l'écran requise pour l'app qui lance la commande).
- Montage : ffmpeg (fond, masque arrondi, ombre, légendes PNG, intro/outro) → `site/video/coran-demo.mp4` (1080p, ~55 s, sans son).

## À faire
Audio de récitation (vrai récitant), mémorisation (hifz) avec répétition espacée, plus de leçons (tajwid, grammaire), Bukhari/Muslim, Riyad as-Salihin (pas de source libre trouvée), icône.
