import SwiftUI
import CoreText

@main
struct CoranApp: App {
    @State private var st = AppState()

    init() {
        if let dir = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
           let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for f in files where f.pathExtension == "ttf" {
                CTFontManagerRegisterFontsForURL(f as CFURL, .process, nil)
            }
        }
    }

    /// Mode film : CORAN_FILM=/dossier joue un scénario et capture ses images (frames.txt = temps + fichier).
    func filmIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["CORAN_FILM"] else { return }
        Audio.shared.enabled = false; Audio.shared.voiceOn = false
        var d = Profile()
        d.name = env["CORAN_NAME"] ?? "Yassine"; d.onboarded = true; d.accent = 0
        d.xp = 145; d.streak = 4; d.bestStreak = 4; d.lastDay = st.today
        d.daily = [st.today: 20]; d.done = ["alpha1", "alpha2"]; d.badges = ["first", "lesson1"]
        d.read = ["1:1", "1:2"]
        st.p = d
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        for i in 0..<30 where i % 3 != 2 {
            let k = f.string(from: Calendar.current.date(byAdding: .day, value: -i, to: Date())!)
            st.times[k] = ["read": Double(300 + (i * 97) % 900), "listen": Double((i * 53) % 500), "learn": Double(200 + (i * 71) % 600)]
        }
        st.quiz = ["answered": 80, "correct": 66]
        st.mode = .coran; st.surahNumber = 1; st.scrollTo = 1; st.tipDismissed = true

        var events = ""
        func at(_ t: Double, _ name: String = "", _ block: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                block()
                if !name.isEmpty { events += "\(name) \(Date().timeIntervalSince1970)\n" }
            }
        }

        func timeline() {
            try? "\(Date().timeIntervalSince1970)".write(toFile: "\(dir)/t0.txt", atomically: true, encoding: .utf8)
            // Scène 1 : récitation qui suit le texte
            at(0.6, "s1") { st.reciter.start(1, from: 1) }
            at(7.0, "s2") { st.reciter.stop(); st.paletteOpen = true }
            // Scène 2 : recherche ⌘K puis contexte de la sourate
            for (t, q) in [(7.8, "k"), (8.2, "ka"), (8.6, "kah"), (9.0, "kahf")] { at(t) { st.demoQuery = q } }
            at(10.6, "s2b") { st.demoCmd = "palette-go#1" }
            // Scène 3 : verset, mots expliqués, panneau de contexte
            at(15.0, "s3") { st.open(Ref(surah: 2, ayah: 3)) }
            at(17.4, "s3b") { st.info = AppState.InfoTarget(ref: Ref(surah: 2, ayah: 3), focus: "salat") }
            at(22.0) { st.info = nil }
            // Scène 4 : parcours d'arabe et leçon
            at(22.3, "s4") { st.mode = .learn }
            at(25.8, "s4b") { st.lesson = Curriculum.all.first { $0.id == "alpha3" } }
            at(28.6) { st.demoCmd = "pick-correct#1" }
            at(29.9) { st.demoCmd = "check#1" }
            at(32.0) { st.demoCmd = "next#1" }
            at(33.4) { st.demoCmd = "pick-correct#2" }
            at(34.6) { st.demoCmd = "check#2" }
            at(36.6) { st.lesson = nil }
            // Scène 5 : stats
            at(36.9, "s5") { st.showStats = true }
            at(40.9) { st.showStats = false; st.mode = .coran; st.surahNumber = 1; st.scrollTo = 1 }
            // Scène 6 : couleurs et thèmes
            at(41.1, "s6") { st.p.accent = 1 }
            for i in 2..<6 { at(41.1 + Double(i - 1) * 0.5) { st.p.accent = i } }
            at(43.4) { st.p.accent = 0; st.theme = .sepia }
            at(45.0) { st.theme = .light }
            at(46.6) { st.theme = .dark }
            at(48.2, "end") {
                try? events.write(toFile: "\(dir)/events.txt", atomically: true, encoding: .utf8)
                try? "done".write(toFile: "\(dir)/done.txt", atomically: true, encoding: .utf8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { NSApp.terminate(nil) }
            }
        }

        // Attend le signal « go » (fichier) pour partir : l'enregistrement d'écran démarre avant.
        let waiter = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            if FileManager.default.fileExists(atPath: "\(dir)/go") { t.invalidate(); timeline() }
        }
        _ = waiter
    }

    /// Mode test : CORAN_SNAPSHOT=/chemin/dossier  CORAN_SURAH=2  CORAN_QUERY=bakara
    func snapshotIfRequested() {
        guard let dir = ProcessInfo.processInfo.environment["CORAN_SNAPSHOT"] else { return }
        let env = ProcessInfo.processInfo.environment
        if let s = env["CORAN_SURAH"], let n = Int(s) { st.openSurah(n) }
        if let s = env["CORAN_SURAH"], let n = Int(s), let a = env["CORAN_AYAH"], let k = Int(a) { st.open(Ref(surah: n, ayah: k)) }
        if let b = env["CORAN_BOOK"] { st.openHadith(b, Int(env["CORAN_HADITH_N"] ?? "")) }
        if env["CORAN_DEMO"] != nil {
            var d = Profile()
            d.name = env["CORAN_NAME"] ?? "Gaïsse"; d.onboarded = true; d.accent = Int(env["CORAN_ACCENT"] ?? "1") ?? 1
            d.xp = 145; d.streak = 4; d.bestStreak = 4; d.lastDay = st.today
            d.daily = [st.today: 20]; d.done = ["alpha1", "alpha2"]; d.badges = ["first", "lesson1"]
            d.read = ["1:1", "1:2"]
            st.p = d
        }
        if let pl = env["CORAN_PLAY"]?.split(separator: ":").compactMap({ Int($0) }), pl.count == 2 {
            st.mode = .coran; st.surahNumber = pl[0]; st.scrollTo = pl[1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { st.reciter.start(pl[0], from: pl[1]) }
        }
        if let ck = env["CORAN_CHECK"]?.split(separator: ":").compactMap({ Int($0) }), ck.count == 2 { st.mode = .coran; st.surahNumber = ck[0]; st.checkRef = Ref(surah: ck[0], ayah: ck[1]) }
        if let inf = env["CORAN_INFO"]?.split(separator: ":").compactMap({ Int($0) }), inf.count == 2 {
            st.mode = .coran; st.surahNumber = inf[0]; st.scrollTo = inf[1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { st.info = AppState.InfoTarget(ref: Ref(surah: inf[0], ayah: inf[1]), focus: env["CORAN_FOCUS"]) }
        }
        if env["CORAN_STATS"] != nil {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            for i in 0..<30 where i % 3 != 2 {
                let k = f.string(from: Calendar.current.date(byAdding: .day, value: -i, to: Date())!)
                st.times[k] = ["read": Double(300 + (i * 97) % 900), "listen": Double((i * 53) % 500), "learn": Double(200 + (i * 71) % 600)]
            }
            st.quiz = ["answered": 80, "correct": 66]
            st.showStats = true
        }
        if env["CORAN_MODE"] == "learn" { st.mode = .learn }
        if env["CORAN_SETTINGS"] != nil { st.showSettings = true }
        if let id = env["CORAN_LESSON"] { st.lesson = Curriculum.all.first { $0.id == id } }
        if env["CORAN_ONBOARD"] != nil { st.p.onboarded = false }
        if let t = env["CORAN_THEME"], let k = ThemeKind(rawValue: t) { st.theme = k }
        func shot(_ name: String) {
            guard let v = NSApp.windows.first?.contentView,
                  let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { return }
            v.cacheDisplay(in: v.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(env["CORAN_DELAY"] ?? "") ?? 2)) {
            shot("reader")
            st.paletteOpen = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                shot("palette")
                NSApp.terminate(nil)
            }
        }
    }

    var body: some Scene {
        WindowGroup("Coran") {
            RootView(st: st).onAppear { snapshotIfRequested(); filmIfRequested() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Rechercher…") { st.paletteOpen.toggle() }.keyboardShortcut("k")
            }
            CommandMenu("Lecture") {
                Button("Agrandir l'arabe") { st.bump(2) }.keyboardShortcut("+")
                Button("Réduire l'arabe") { st.bump(-2) }.keyboardShortcut("-")
                Button("Changer de thème") { st.theme = st.theme.next }.keyboardShortcut("l", modifiers: [.command, .shift])
                Button(st.showFR ? "Masquer la traduction" : "Afficher la traduction") { st.showFR.toggle() }
                    .keyboardShortcut("t")
                Divider()
                Button("Sourate suivante") { st.openSurah(min(114, st.surahNumber + 1)) }.keyboardShortcut("]")
                Button("Sourate précédente") { st.openSurah(max(1, st.surahNumber - 1)) }.keyboardShortcut("[")
            }
        }
    }
}
