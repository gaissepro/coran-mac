import SwiftUI

// MARK: - En-tête de sourate enrichi

struct Pill2: View {
    let st: AppState; let text: String; var symbol: String? = nil
    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.system(size: 10)) }
            Text(text).font(.custom("Inter", size: 11).weight(.medium))
        }
        .foregroundStyle(st.pal.muted)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .overlay(Capsule().stroke(st.pal.line.opacity(2)))
    }
}

struct SurahHeader: View {
    @Bindable var st: AppState
    let s: Surah

    var body: some View {
        let here = st.reciter.surah == s.n
        VStack(spacing: 12) {
            Text("سُورَةُ \(s.ar)")
                .font(.custom("Amiri Quran", size: st.arSize * 1.9))
                .foregroundStyle(st.pal.fg)
                .environment(\.layoutDirection, .rightToLeft)
            Text(Meta.frName(s.n))
                .font(.custom("Literata", size: 24).weight(.semibold)).foregroundStyle(st.pal.fg)
            Text("\(s.en) · \(s.tr)")
                .font(.custom("Literata", size: 14).weight(.light)).foregroundStyle(st.pal.muted)

            HStack(spacing: 8) {
                Pill2(st: st, text: "\(s.ayahs.count) versets", symbol: "text.alignleft")
                Pill2(st: st, text: Meta.place(s.n), symbol: Meta.place(s.n) == "Mecquoise" ? "building.columns" : "moon.stars")
                if let o = Meta.order(s.n) { Pill2(st: st, text: "\(o)ᵉ révélée", symbol: "clock") }
                Pill2(st: st, text: "Sourate \(s.n)/114", symbol: "number")
            }
            .padding(.top, 2)

            if let ctx = Meta.context(s.n) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Contexte de révélation", systemImage: "scroll")
                        .font(.custom("Inter", size: 11).weight(.bold)).tracking(0.8).textCase(.uppercase)
                        .foregroundStyle(st.accentColor)
                    Text(ctx).font(.custom("Literata", size: 15)).lineSpacing(4).foregroundStyle(st.pal.fg.opacity(0.88))
                    Text("Résumé général fondé sur les repères traditionnels. Pour le détail, consulte un tafsir.")
                        .font(.custom("Inter", size: 10.5)).foregroundStyle(st.pal.muted)
                }
                .padding(16).frame(maxWidth: 620, alignment: .leading)
                .background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.pal.line))
                .padding(.top, 6)
            }

            HStack(spacing: 10) {
                Button {
                    Audio.shared.play(.tap)
                    if here { st.reciter.toggle() } else { st.reciter.start(s.n) }
                } label: {
                    Label(here && st.reciter.playing ? "Pause" : "Écouter la sourate",
                          systemImage: here && st.reciter.playing ? "pause.fill" : "play.fill")
                        .font(.custom("Inter", size: 13).weight(.bold))
                        .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(st.accentColor, in: Capsule())
                }.buttonStyle(.plain)

                Menu {
                    Button("Hamidullah (classique)") { st.translation = "hamidullah" }
                    Button("Montada (moderne, avec notes)") { st.translation = "montada" }
                } label: {
                    Label(st.translation == "montada" ? "Traduction : Montada" : "Traduction : Hamidullah", systemImage: "character.book.closed")
                        .font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.pal.muted)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .overlay(Capsule().stroke(st.pal.line.opacity(2)))
                }
                .menuStyle(.borderlessButton).fixedSize()
            }
            .padding(.top, 8)

            if st.showGloss && !st.tipDismissed {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(st.accentColor)
                    Text("Les petits mots sous un verset sont expliqués : clique dessus. Le bouton ⓘ ouvre le contexte et les notes du verset.")
                        .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                    Button("Compris") { Audio.shared.play(.tap); st.tipDismissed = true }
                        .buttonStyle(.plain).font(.custom("Inter", size: 12).weight(.bold)).foregroundStyle(st.accentColor)
                }
                .padding(14).frame(maxWidth: 620)
                .background(st.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .padding(.top, 6)
            }

            if s.n != 1 && s.n != 9 {
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                    .font(.custom("Amiri Quran", size: st.arSize * 1.15))
                    .foregroundStyle(here && st.reciter.ayah == 0 && st.reciter.playing ? st.accentColor : st.pal.fg)
                    .padding(.top, 18)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 62).padding(.bottom, 26)
    }
}

// MARK: - Mots expliqués sous un verset

struct GlossChips: View {
    let st: AppState; let ref: Ref; let entries: [GlossEntry]
    var body: some View {
        Flow(spacing: 8, rtl: false) {
            Text("Mots expliqués").font(.custom("Inter", size: 10.5).weight(.bold)).tracking(0.8).textCase(.uppercase)
                .foregroundStyle(st.pal.muted).padding(.trailing, 2)
            ForEach(entries.prefix(5)) { e in
                Button { Audio.shared.play(.soft); st.info = AppState.InfoTarget(ref: ref, focus: e.id) } label: {
                    HStack(spacing: 6) {
                        Text(e.ar).font(.custom("Amiri Quran", size: 17))
                        Image(systemName: "questionmark.circle").font(.system(size: 10))
                    }
                    .foregroundStyle(st.accentColor)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(st.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain).help(e.text)
            }
        }
    }
}

// MARK: - Panneau « Contexte et infos du verset »

struct InfoPanel: View {
    @Bindable var st: AppState
    let target: AppState.InfoTarget

    var s: Surah? { Quran.surah(target.ref.surah) }
    var verse: Ayah? { s?.ayahs.first { $0.n == target.ref.ayah } }

    var body: some View {
        ZStack {
            Color.black.opacity(st.theme == .dark ? 0.6 : 0.3).ignoresSafeArea().onTapGesture { st.info = nil }
            if let s, let v = verse {
                let entries = Glossary.forVerse(s.n, v)
                let focus = entries.first { $0.id == target.focus }
                let ordered = (focus.map { [$0] } ?? []) + entries.filter { $0.id != target.focus }
                let notes = Meta.notes(s.n, v.n)
                VStack(spacing: 0) {
                    HStack {
                        Text("\(Meta.frName(s.n)) · \(s.n):\(v.n)").font(.custom("Inter", size: 13).weight(.semibold)).foregroundStyle(st.pal.muted)
                        Spacer()
                        Button { Audio.shared.play(.tap); st.info = nil } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(st.pal.muted)
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 16)
                    Rectangle().fill(st.pal.line).frame(height: 1)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if let f = focus { entryCard(f, focused: true) }
                            Text("\u{2067}\(v.ar) \u{FD3F}\(arabicDigits(v.n))\u{FD3E}\u{2069}")
                                .font(.custom("Amiri Quran", size: 28)).lineSpacing(14)
                                .foregroundStyle(st.pal.fg).multilineTextAlignment(.leading)
                                .environment(\.layoutDirection, .rightToLeft)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text(st.verseFR(s.n, v)).font(.custom("Literata", size: 15)).lineSpacing(4).foregroundStyle(st.pal.muted)

                            if (focus == nil ? !ordered.isEmpty : ordered.count > 1) {
                                section(focus == nil ? "Mots importants" : "Autres mots importants", symbol: "text.magnifyingglass")
                                ForEach(focus == nil ? ordered : Array(ordered.dropFirst())) { e in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(e.title).font(.custom("Amiri Quran", size: 22)).foregroundStyle(st.accentColor)
                                        Text(e.text).font(.custom("Literata", size: 14.5)).lineSpacing(4).foregroundStyle(st.pal.fg.opacity(0.9))
                                    }
                                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(e.id == target.focus ? st.accentColor.opacity(0.12) : st.pal.card, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(e.id == target.focus ? st.accentColor.opacity(0.6) : st.pal.line))
                                }
                            }
                            if !notes.isEmpty {
                                section("Notes de la traduction Montada", symbol: "note.text")
                                ForEach(Array(notes.enumerated()), id: \.offset) { _, n in
                                    Text(n).font(.custom("Literata", size: 14.5)).lineSpacing(4).foregroundStyle(st.pal.fg.opacity(0.9))
                                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                        .background(st.pal.card, in: RoundedRectangle(cornerRadius: 12))
                                }
                                Text("Source : traduction française de la Fondation Montada, via QuranEnc.com. Ces notes reflètent le point de vue de leurs auteurs.")
                                    .font(.custom("Inter", size: 10.5)).foregroundStyle(st.pal.muted)
                            }
                            if ordered.isEmpty && notes.isEmpty {
                                Text("Pas de note ni de mot expliqué pour ce verset pour l'instant.")
                                    .font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted)
                            }
                        }
                        .padding(24)
                    }
                }
                .frame(width: 680, height: 640)
                .background(st.pal.bg, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(st.pal.line.opacity(2)))
                .shadow(color: .black.opacity(0.4), radius: 40, y: 16)
            }
        }
        .onExitCommand { st.info = nil }
    }

    func entryCard(_ e: GlossEntry, focused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(e.title).font(.custom("Amiri Quran", size: 24)).foregroundStyle(st.accentColor)
            Text(e.text).font(.custom("Literata", size: 15)).lineSpacing(4).foregroundStyle(st.pal.fg.opacity(0.92))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(st.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(st.accentColor.opacity(0.6)))
    }

    func section(_ t: String, symbol: String) -> some View {
        Label(t, systemImage: symbol).font(.custom("Inter", size: 11).weight(.bold)).tracking(0.8).textCase(.uppercase)
            .foregroundStyle(st.pal.muted).padding(.top, 6)
    }
}

// MARK: - Statistiques

struct StatsView: View {
    @Bindable var st: AppState

    static let catColors: [(key: String, label: String, color: Color)] = [
        ("read", "Lecture", Color(hex: 0x8FD9B6)),
        ("listen", "Écoute", Color(hex: 0xF6B47B)),
        ("learn", "Apprentissage", Color(hex: 0xB7A7F0)),
    ]

    func dayKey(_ offset: Int) -> String {
        AppState.dayKey(Calendar.current.date(byAdding: .day, value: -offset, to: Date())!)
    }
    func total(_ key: String) -> Double { st.times[key]?.values.reduce(0, +) ?? 0 }
    func fmt(_ sec: Double) -> String {
        let m = Int((sec / 60).rounded())
        if sec < 60 { return "\(Int(sec)) s" }
        if m < 60 { return "\(m) min" }
        return "\(m / 60) h \(String(format: "%02d", m % 60))"
    }
    var week: [String] { (0..<7).map { dayKey(6 - $0) } }
    var weekTotal: Double { week.reduce(0) { $0 + total($1) } }
    var allTotal: Double { st.times.values.reduce(0) { $0 + $1.values.reduce(0, +) } }
    var accuracy: String {
        let a = st.quiz["answered"] ?? 0, c = st.quiz["correct"] ?? 0
        return a == 0 ? "—" : "\(Int(Double(c) / Double(a) * 100)) %"
    }
    var surahsDone: Int { st.p.badges.filter { $0.hasPrefix("surah") }.count }

    func tile(_ symbol: String, _ color: Color, _ value: String, _ label: String) -> some View {
        StatPill(st: st, symbol: symbol, color: color, value: value, label: label)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(st.theme == .dark ? 0.6 : 0.3).ignoresSafeArea().onTapGesture { st.showStats = false }
            VStack(spacing: 0) {
                HStack {
                    Text("Mes stats").font(.custom("Literata", size: 22).weight(.semibold)).foregroundStyle(st.pal.fg)
                    Spacer()
                    Button { Audio.shared.play(.tap); st.showStats = false } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.vertical, 18)
                Rectangle().fill(st.pal.line).frame(height: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 10) {
                            tile("clock.fill", st.accentColor, fmt(total(st.today)), "aujourd'hui")
                            tile("calendar", Color(hex: 0xF6B47B), fmt(weekTotal), "7 derniers jours")
                            tile("hourglass", Color(hex: 0xB7A7F0), fmt(allTotal), "au total")
                        }
                        HStack(spacing: 10) {
                            tile("flame.fill", .orange, "\(st.liveStreak)", "jours de suite · record \(st.p.bestStreak)")
                            tile("bolt.fill", Color(hex: 0xFFC83D), "\(st.p.xp)", "XP · niveau \(st.level)")
                        }

                        Text("Cette semaine").font(.custom("Inter", size: 11).weight(.bold)).tracking(0.8).textCase(.uppercase).foregroundStyle(st.pal.muted)
                        bars
                        HStack(spacing: 16) {
                            ForEach(Self.catColors, id: \.key) { c in
                                HStack(spacing: 6) {
                                    Circle().fill(c.color).frame(width: 9, height: 9)
                                    Text("\(c.label) · \(fmt(st.times.values.reduce(0) { $0 + ($1[c.key] ?? 0) }))")
                                        .font(.custom("Inter", size: 11.5)).foregroundStyle(st.pal.muted)
                                }
                            }
                        }

                        Text("Régularité (12 semaines)").font(.custom("Inter", size: 11).weight(.bold)).tracking(0.8).textCase(.uppercase).foregroundStyle(st.pal.muted)
                        heat

                        Text("Progression").font(.custom("Inter", size: 11).weight(.bold)).tracking(0.8).textCase(.uppercase).foregroundStyle(st.pal.muted)
                        HStack(spacing: 10) {
                            tile("book.fill", st.accentColor, "\(st.p.read.count)", "versets lus")
                            tile("checkmark.seal.fill", Color(hex: 0x8FD9B6), "\(surahsDone)", "sourates terminées")
                        }
                        HStack(spacing: 10) {
                            tile("graduationcap.fill", Color(hex: 0xB7A7F0), "\(st.p.done.filter { $0 != "review" }.count)/\(Curriculum.all.count)", "leçons faites")
                            tile("target", Color(hex: 0xF4A6C0), accuracy, "de réussite aux exercices")
                        }
                        if st.weakCount > 0 {
                            Text("\(st.weakCount) élément\(st.weakCount > 1 ? "s" : "") à retenir dans la révision du jour.")
                                .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                        }
                        Text("Le temps compte quand l'app est au premier plan, par activité : lecture, écoute et leçons.")
                            .font(.custom("Inter", size: 10.5)).foregroundStyle(st.pal.muted)
                    }
                    .padding(24)
                }
            }
            .frame(width: 640, height: 680)
            .background(st.pal.bg, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(st.pal.line.opacity(2)))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 16)
        }
        .onExitCommand { st.showStats = false }
    }

    var bars: some View {
        let maxV = max(1800, week.map { total($0) }.max() ?? 0)   // échelle minimale : 30 min
        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(week, id: \.self) { d in
                let parts = Self.catColors.map { ($0.color, st.times[d]?[$0.key] ?? 0) }
                VStack(spacing: 6) {
                    Text(total(d) > 0 ? "\(Int((total(d) / 60).rounded()))" : "").font(.custom("Inter", size: 10)).foregroundStyle(st.pal.muted)
                    VStack(spacing: 1) {
                        Spacer(minLength: 0)
                        ForEach(Array(parts.enumerated()), id: \.offset) { _, p in
                            if p.1 > 0 { RoundedRectangle(cornerRadius: 3).fill(p.0).frame(height: max(3, CGFloat(p.1 / maxV) * 120)) }
                        }
                    }
                    .frame(height: 120)
                    Text(weekday(d)).font(.custom("Inter", size: 10.5).weight(d == st.today ? .bold : .regular))
                        .foregroundStyle(d == st.today ? st.pal.fg : st.pal.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14).background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
    }

    func weekday(_ key: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let d = f.date(from: key) else { return "" }
        let o = DateFormatter(); o.locale = Locale(identifier: "fr_FR"); o.dateFormat = "EEE"
        return o.string(from: d)
    }

    var heat: some View {
        // 12 colonnes (semaines) × 7 lignes (jours) ; la dernière colonne se termine aujourd'hui.
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { w in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { r in
                        let off = (11 - w) * 7 + (6 - r)
                        let v = total(dayKey(off))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(v == 0 ? st.pal.card : st.accentColor.opacity(min(1, 0.3 + v / 1800 * 0.7)))
                            .frame(height: 16)
                            .help("\(dayKey(off)) · \(fmt(v))")
                    }
                }
            }
        }
        .padding(14).background(st.pal.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}
