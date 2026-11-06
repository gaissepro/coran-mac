import SwiftUI
import Observation

enum Mode: String { case coran, hadith, learn }

enum ThemeKind: String, CaseIterable, Codable {
    case dark, sepia, light
    var label: String { ["dark": "Sombre", "sepia": "Sépia", "light": "Clair"][rawValue]! }
    var next: ThemeKind {
        let all = ThemeKind.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

let accents: [(name: String, hex: UInt32)] = [
    ("Menthe", 0x8FD9B6), ("Pêche", 0xF6B47B), ("Lavande", 0xB7A7F0),
    ("Rose", 0xF4A6C0), ("Ciel", 0x8EC9F2), ("Citron", 0xF2DC7E),
]

struct Palette {
    let bg, card, fg, muted, line, accent: Color
    let scheme: ColorScheme
    static let good = Color(hex: 0x34C759)
    static let bad = Color(hex: 0xFF5A52)

    static func of(_ t: ThemeKind, accent: Color) -> Palette {
        switch t {
        case .dark:
            return Palette(bg: Color(hex: 0x0A0A0B), card: Color(hex: 0x161618), fg: Color(hex: 0xF4F4F5),
                           muted: Color(hex: 0x8E8E93), line: Color.white.opacity(0.08), accent: accent, scheme: .dark)
        case .sepia:
            return Palette(bg: Color(hex: 0xF4ECD8), card: Color(hex: 0xEADFC4), fg: Color(hex: 0x3B2F20),
                           muted: Color(hex: 0x8A7A5F), line: Color.black.opacity(0.08), accent: accent, scheme: .light)
        case .light:
            return Palette(bg: Color(hex: 0xFBFBFA), card: Color(hex: 0xF0F0EE), fg: Color(hex: 0x1C1C1E),
                           muted: Color(hex: 0x76767B), line: Color.black.opacity(0.08), accent: accent, scheme: .light)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct Profile: Codable {
    var name = ""
    var onboarded = false
    var goalXP = 30
    var level = "debutant"      // debutant, base, avance
    var intent = "lire"         // lire, arabe, memoriser
    var accent = 0
    var sound = true
    var voice = true
    var xp = 0
    var streak = 0
    var bestStreak = 0
    var lastDay = ""
    var daily: [String: Int] = [:]
    var read: Set<String> = []
    var done: Set<String> = []
    var badges: Set<String> = []
    var perfect = 0
}

@Observable
final class AppState {
    var surahNumber: Int { didSet { UserDefaults.standard.set(surahNumber, forKey: "surah") } }
    var scrollTo: Int? = nil
    var highlight: Int? = nil
    var showFR: Bool { didSet { UserDefaults.standard.set(showFR, forKey: "showFR") } }
    var theme: ThemeKind { didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") } }
    var arSize: Double { didSet { UserDefaults.standard.set(arSize, forKey: "arSize") } }
    var favorites: Set<String> { didSet { UserDefaults.standard.set(Array(favorites), forKey: "favs") } }
    var lastAyah: [Int: Int] { didSet {
        UserDefaults.standard.set(Dictionary(uniqueKeysWithValues: lastAyah.map { (String($0.key), $0.value) }), forKey: "last")
    } }
    var mode: Mode { didSet { UserDefaults.standard.set(mode.rawValue, forKey: "mode") } }
    var bookId: String { didSet { UserDefaults.standard.set(bookId, forKey: "book") } }
    var p: Profile { didSet { saveProfile() } }
    var miss: [String: Int] { didSet { UserDefaults.standard.set(miss, forKey: "miss.v1") } }
    var rewarded: Set<String> { didSet { UserDefaults.standard.set(Array(rewarded), forKey: "rewarded.v1") } }
    let reciter = Reciter()
    var checkRef: Ref? = nil
    var info: InfoTarget? = nil
    var demoQuery: String? = nil     // mode film : texte tapé dans la recherche
    var demoCmd: String? = nil       // mode film : commandes pilotées (leçon, recherche)
    var showStats = false
    var translation: String { didSet { UserDefaults.standard.set(translation, forKey: "translation") } }
    var showGloss: Bool { didSet { UserDefaults.standard.set(showGloss, forKey: "showGloss") } }
    var tipDismissed: Bool { didSet { UserDefaults.standard.set(tipDismissed, forKey: "tipDismissed") } }
    var times: [String: [String: Double]] = [:]
    var quiz: [String: Int] { didSet { UserDefaults.standard.set(quiz, forKey: "quiz.v1") } }
    private var tickCount = 0
    var paletteOpen = false
    var showFavorites = false
    var showSettings = false
    var lesson: Lesson? = nil
    var toast: String? = nil
    var confetti = 0

    var accentColor: Color { Color(hex: accents[min(max(p.accent, 0), accents.count - 1)].hex) }
    var pal: Palette { Palette.of(theme, accent: accentColor) }
    var surah: Surah { Quran.surah(surahNumber) ?? Quran.surahs[0] }

    init() {
        let d = UserDefaults.standard
        surahNumber = max(1, d.integer(forKey: "surah"))
        mode = Mode(rawValue: d.string(forKey: "mode") ?? "") ?? .coran
        bookId = d.string(forKey: "book") ?? "nawawi"
        showFR = d.object(forKey: "showFR") as? Bool ?? true
        theme = ThemeKind(rawValue: d.string(forKey: "theme") ?? "") ?? .dark
        let s = d.double(forKey: "arSize")
        arSize = s == 0 ? 34 : s
        favorites = Set(d.stringArray(forKey: "favs") ?? [])
        let l = (d.dictionary(forKey: "last") as? [String: Int]) ?? [:]
        lastAyah = Dictionary(uniqueKeysWithValues: l.compactMap { k, v in Int(k).map { ($0, v) } })
        if let data = d.data(forKey: "profile.v1"), let pr = try? JSONDecoder().decode(Profile.self, from: data) {
            p = pr
        } else {
            p = Profile()
        }
        translation = d.string(forKey: "translation") ?? "hamidullah"
        showGloss = d.object(forKey: "showGloss") as? Bool ?? true
        tipDismissed = d.bool(forKey: "tipDismissed")
        quiz = (d.dictionary(forKey: "quiz.v1") as? [String: Int]) ?? [:]
        times = (d.dictionary(forKey: "time.v1") as? [String: [String: Double]]) ?? [:]
        miss = (d.dictionary(forKey: "miss.v1") as? [String: Int]) ?? [:]
        rewarded = Set(d.stringArray(forKey: "rewarded.v1") ?? [])
        Audio.shared.enabled = p.sound
        Audio.shared.voiceOn = p.voice
        reciter.onFinish = { [weak self] s in self?.listenedFully(s) }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    struct InfoTarget: Equatable { let ref: Ref; let focus: String? }

    /// Compte le temps passé dans l'app (au premier plan) par activité.
    func tick() {
        guard NSApp.isActive, !p.name.isEmpty || p.onboarded else { return }
        let cat = lesson != nil ? "learn" : (reciter.playing ? "listen" : (mode == .learn ? "learn" : "read"))
        times[today, default: [:]][cat, default: 0] += 1
        tickCount += 1
        if tickCount % 10 == 0, ProcessInfo.processInfo.environment["CORAN_SNAPSHOT"] == nil, ProcessInfo.processInfo.environment["CORAN_FILM"] == nil {
            UserDefaults.standard.set(times, forKey: "time.v1")
        }
    }

    func verseFR(_ s: Int, _ a: Ayah) -> String {
        translation == "montada" ? (Meta.montada(s, a.n) ?? a.fr) : a.fr
    }

    func saveProfile() {
        if ProcessInfo.processInfo.environment["CORAN_SNAPSHOT"] != nil || ProcessInfo.processInfo.environment["CORAN_FILM"] != nil { Audio.shared.enabled = false; return }
        if let data = try? JSONEncoder().encode(p) { UserDefaults.standard.set(data, forKey: "profile.v1") }
        Audio.shared.enabled = p.sound
        Audio.shared.voiceOn = p.voice
    }

    func open(_ ref: Ref) {
        mode = .coran
        surahNumber = ref.surah
        highlight = ref.ayah
        scrollTo = ref.ayah
        paletteOpen = false
    }

    func openHadith(_ book: String, _ n: Int?) {
        mode = .hadith
        bookId = book
        highlight = n
        scrollTo = n ?? 1
        paletteOpen = false
    }

    func openSurah(_ n: Int) {
        mode = .coran
        surahNumber = n
        highlight = nil
        scrollTo = lastAyah[n] ?? 1
        paletteOpen = false
    }

    func toggleFavorite(_ r: Ref) {
        if favorites.contains(r.key) { favorites.remove(r.key) } else { favorites.insert(r.key) }
    }

    func bump(_ delta: Double) { arSize = min(72, max(22, arSize + delta)) }
}
