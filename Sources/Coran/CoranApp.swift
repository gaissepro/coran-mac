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
            RootView(st: st).onAppear { snapshotIfRequested() }
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
