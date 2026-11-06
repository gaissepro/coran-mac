import SwiftUI
import AppKit
import AVFoundation

// MARK: - Sons

enum Sfx: String {
    case tap = "Pop", ok = "Glass", bad = "Basso", done = "Hero", level = "Funk", soft = "Tink"
}

final class Audio {
    static let shared = Audio()
    var enabled = true
    var voiceOn = true
    private let synth = AVSpeechSynthesizer()
    private var live: [NSSound] = []

    func play(_ s: Sfx) {
        guard enabled, let base = NSSound(named: s.rawValue), let snd = base.copy() as? NSSound else { return }
        live.append(snd)
        snd.play()
        live.removeAll { !$0.isPlaying }
    }

    /// Prononce un texte arabe avec la voix système (Majed).
    func speak(_ text: String) {
        guard voiceOn else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "ar-001") ?? AVSpeechSynthesisVoice(language: "ar-SA")
        u.rate = 0.38
        synth.speak(u)
    }
}

// MARK: - Badges

let badgeInfo: [(id: String, title: String, desc: String, symbol: String)] = [
    ("first", "Premier pas", "Marquer un premier verset comme lu", "leaf.fill"),
    ("read100", "Lecteur", "100 versets lus", "book.fill"),
    ("fatiha", "Al-Fatiha", "Lire toute la sourate Al-Fatiha", "sparkles"),
    ("lesson1", "Élève", "Terminer une première leçon", "graduationcap.fill"),
    ("lesson5", "Studieux", "Terminer 5 leçons", "pencil.and.list.clipboard"),
    ("perfect", "Sans faute", "Une leçon sans aucune erreur", "target"),
    ("streak3", "3 jours", "Série de 3 jours", "flame.fill"),
    ("streak7", "Une semaine", "Série de 7 jours", "flame.circle.fill"),
    ("xp500", "500 XP", "Atteindre 500 XP", "bolt.fill"),
]

// MARK: - Logique de progression

extension AppState {
    static func dayKey(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }

    var today: String { Self.dayKey(Date()) }
    var todayXP: Int { p.daily[today] ?? 0 }
    var goalProgress: Double { min(1, Double(todayXP) / Double(max(1, p.goalXP))) }
    var level: Int { p.xp / 100 + 1 }
    var levelProgress: Double { Double(p.xp % 100) / 100 }
    var levelTitle: String {
        ["Débutant", "Lecteur", "Étudiant", "Assidu", "Érudit", "Savant"][min(level - 1, 5)]
    }

    /// Série affichée : retombe à 0 si on a sauté un jour.
    var liveStreak: Int {
        let yesterday = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        return (p.lastDay == today || p.lastDay == yesterday) ? p.streak : 0
    }

    func showToast(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            if self?.toast == msg { self?.toast = nil }
        }
    }

    func award(_ n: Int) {
        let t = today
        let before = p.daily[t] ?? 0
        if p.lastDay != t {
            let yesterday = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
            p.streak = (p.lastDay == yesterday) ? p.streak + 1 : 1
            p.bestStreak = max(p.bestStreak, p.streak)
            p.lastDay = t
        }
        let oldLevel = level
        p.xp += n
        p.daily[t] = before + n
        if before < p.goalXP && before + n >= p.goalXP {
            confetti += 1
            Audio.shared.play(.level)
            showToast("Objectif du jour atteint ! 🎉")
        } else if level > oldLevel {
            Audio.shared.play(.level)
            showToast("Niveau \(level) · \(levelTitle)")
        } else {
            showToast("+\(n) XP")
        }
        checkBadges()
    }

    func unlock(_ id: String) {
        guard !p.badges.contains(id), let b = badgeInfo.first(where: { $0.id == id }) else { return }
        p.badges.insert(id)
        confetti += 1
        Audio.shared.play(.level)
        showToast("Badge débloqué : \(b.title)")
    }

    func checkBadges() {
        if p.read.count >= 1 { unlock("first") }
        if p.read.count >= 100 { unlock("read100") }
        if (1...7).allSatisfy({ p.read.contains("1:\($0)") }) { unlock("fatiha") }
        if p.done.count >= 1 { unlock("lesson1") }
        if p.done.count >= 5 { unlock("lesson5") }
        if p.streak >= 3 { unlock("streak3") }
        if p.streak >= 7 { unlock("streak7") }
        if p.xp >= 500 { unlock("xp500") }
    }

    func isRead(_ key: String) -> Bool { p.read.contains(key) }

    func toggleRead(_ key: String) {
        Audio.shared.play(.tap)
        if p.read.contains(key) { p.read.remove(key); return }
        p.read.insert(key)
        award(5)
        let parts = key.split(separator: ":").compactMap { Int($0) }
        if parts.count == 2, let s = Quran.surah(parts[0]),
           s.ayahs.allSatisfy({ p.read.contains("\(s.n):\($0.n)") }), !p.badges.contains("surah\(s.n)") {
            p.badges.insert("surah\(s.n)")
            confetti += 1
            award(25)
            showToast("Sourate \(s.en) terminée ! +25 XP")
        }
    }

    func listenedFully(_ surah: Int) {
        let key = "listen:\(surah):\(today)"
        guard !rewarded.contains(key) else { return }
        rewarded.insert(key)
        award(10)
    }

    func rewardRecitation(_ r: Ref) {
        let key = "recite:\(r.key):\(today)"
        guard !rewarded.contains(key) else { return }
        rewarded.insert(key)
        award(10)
    }

    func recordResult(_ key: String?, ok: Bool) {
        quiz["answered", default: 0] += 1
        if ok { quiz["correct", default: 0] += 1 }
        guard let key else { return }
        let cur = miss[key] ?? 0
        if ok { if cur > 0 { miss[key] = cur - 1 } } else { miss[key] = cur + 1 }
    }

    /// Éléments déjà vus (lettres, mots), les plus fragiles d'abord.
    func learnedKeys() -> [String] {
        var keys: [String] = []
        for (i, g) in Curriculum.letterGroups.enumerated() where p.done.contains("alpha\(i + 1)") {
            keys += g.map { "L:\($0.ch)" }
        }
        for i in 0..<Curriculum.wordGroupCount where p.done.contains("vocab\(i + 1)") {
            keys += Curriculum.wordGroup(i).map { "W:\($0.ar)" }
        }
        return keys.shuffled().sorted { (miss[$0] ?? 0) > (miss[$1] ?? 0) }
    }

    var weakCount: Int { learnedKeys().filter { (miss[$0] ?? 0) > 0 }.count }

    func reviewLesson() -> Lesson? {
        let keys = Array(learnedKeys().prefix(6))
        guard !keys.isEmpty else { return nil }
        return Lesson(id: "review", unit: "review", title: "Révision", symbol: "arrow.triangle.2.circlepath", xp: 10) {
            let ls = Curriculum.letters.filter { keys.contains("L:\($0.ch)") }
            let ws = Curriculum.words.filter { keys.contains("W:\($0.ar)") }
            return Array((Curriculum.letterQuestions(ls, limit: 8) + Curriculum.wordQuestions(ws, limit: 8)).shuffled().prefix(11))
        }
    }

    func completeLesson(_ l: Lesson, mistakes: Int) {
        if l.id != "review" { p.done.insert(l.id) }
        let perfect = mistakes == 0
        if perfect { p.perfect += 1; unlock("perfect") }
        award(l.xp + (perfect ? 5 : 0))
    }

    func resetProgress() {
        let keep = p
        var n = Profile()
        n.name = keep.name; n.onboarded = true; n.goalXP = keep.goalXP; n.level = keep.level
        n.intent = keep.intent; n.accent = keep.accent; n.sound = keep.sound; n.voice = keep.voice
        p = n
    }
}

// MARK: - Composants

struct Ring: View {
    let progress: Double
    let color: Color
    let track: Color
    var width: CGFloat = 5
    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: width)
            Circle().trim(from: 0, to: max(0.001, progress))
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
        }
    }
}

struct ToastView: View {
    let st: AppState
    var body: some View {
        VStack {
            Spacer()
            if let t = st.toast {
                Text(t)
                    .font(.custom("Inter", size: 14).weight(.semibold))
                    .foregroundStyle(st.pal.bg)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(st.pal.fg, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 28)
            }
        }
        .animation(.spring(duration: 0.35), value: st.toast)
        .allowsHitTesting(false)
    }
}

struct Confetti: View {
    let trigger: Int
    @State private var show = false
    @State private var fall = false
    private let colors: [Color] = [Color(hex: 0xFF5A52), Color(hex: 0xFFC83D), Color(hex: 0x34C759),
                                   Color(hex: 0x5AA9FF), Color(hex: 0xC084FC), Color(hex: 0xF472B6)]

    var body: some View {
        GeometryReader { geo in
            if show {
                ForEach(0..<70, id: \.self) { i in
                    let seed = Double((i * 7919) % 1000) / 1000
                    let seed2 = Double((i * 104729) % 1000) / 1000
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors[i % colors.count])
                        .frame(width: 8 + seed * 6, height: 12 + seed2 * 6)
                        .rotationEffect(.degrees(fall ? 360 * (seed2 + 0.5) * 2 : 0))
                        .position(x: geo.size.width * seed + (fall ? (seed2 - 0.5) * 120 : 0),
                                  y: fall ? geo.size.height + 40 : -30)
                        .animation(.easeIn(duration: 1.6 + seed2 * 1.2).delay(seed * 0.4), value: fall)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            show = true; fall = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { fall = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) { show = false }
        }
    }
}

/// Mise en page en lignes qui passent à la ligne (tuiles de mots).
struct Flow: Layout {
    var spacing: CGFloat = 8
    var rtl = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 600
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
            w = max(w, x - spacing)
        }
        return CGSize(width: w, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(Subviews.Element, CGSize)]] = [[]]
        var x: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.width && x > 0 { rows.append([]); x = 0 }
            rows[rows.count - 1].append((s, sz))
            x += sz.width + spacing
        }
        var y = bounds.minY
        for row in rows {
            let rowH = row.map { $0.1.height }.max() ?? 0
            let rowW = row.reduce(0) { $0 + $1.1.width } + spacing * CGFloat(max(0, row.count - 1))
            var cx = rtl ? bounds.maxX : bounds.midX - rowW / 2
            if rtl { cx = bounds.maxX }
            for (s, sz) in row {
                if rtl {
                    s.place(at: CGPoint(x: cx - sz.width, y: y), proposal: .unspecified)
                    cx -= sz.width + spacing
                } else {
                    s.place(at: CGPoint(x: cx, y: y), proposal: .unspecified)
                    cx += sz.width + spacing
                }
            }
            y += rowH + spacing
        }
    }
}
