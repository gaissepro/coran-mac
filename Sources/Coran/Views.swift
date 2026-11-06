import SwiftUI
import AppKit

// MARK: - Racine

struct RootView: View {
    @Bindable var st: AppState

    var body: some View {
        ZStack {
            st.pal.bg.ignoresSafeArea()
            HStack(spacing: 0) {
                Sidebar(st: st)
                    .frame(width: 270)
                Rectangle().fill(st.pal.line).frame(width: 1)
                switch st.mode {
                case .coran: Reader(st: st)
                case .hadith: HadithReader(st: st)
                case .learn: LearnHome(st: st)
                }
            }
            if st.paletteOpen {
                PaletteView(st: st)
                    .transition(.opacity)
            }
            if let l = st.lesson {
                LessonView(st: st, lesson: l).id(l.id)
                    .transition(.move(edge: .bottom).combined(with: .opacity)).zIndex(5)
            }
            if let t = st.info { InfoPanel(st: st, target: t).id(t.ref.key + (t.focus ?? "")).transition(.opacity).zIndex(6) }
            if st.showStats { StatsView(st: st).transition(.opacity).zIndex(6) }
            if let r = st.checkRef { RecitePanel(st: st, ref: r).id(r.key).transition(.opacity).zIndex(7) }
            if st.showSettings { SettingsView(st: st).transition(.opacity).zIndex(6) }
            if !st.p.onboarded { Onboarding(st: st).transition(.opacity).zIndex(8) }
            Confetti(trigger: st.confetti).zIndex(9)
            ToastView(st: st).zIndex(10)
        }
        .animation(.easeInOut(duration: 0.3), value: st.lesson?.id)
        .animation(.easeInOut(duration: 0.2), value: st.showSettings)
        .animation(.easeInOut(duration: 0.2), value: st.showStats)
        .animation(.easeInOut(duration: 0.2), value: st.info)
        .animation(.easeInOut(duration: 0.3), value: st.p.onboarded)
        .preferredColorScheme(st.pal.scheme)
        .animation(.easeOut(duration: 0.12), value: st.paletteOpen)
        .frame(minWidth: 940, minHeight: 640)
    }
}

// MARK: - Barre latérale

struct Sidebar: View {
    @Bindable var st: AppState
    @State private var filter = ""

    var list: [Surah] {
        let f = Search.translit(filter)
        guard !filter.isEmpty else { return Quran.surahs }
        return Quran.surahs.filter {
            Search.translit($0.en).contains(f) || fold($0.ar).contains(fold(filter)) || String($0.n) == filter
        }
    }

    var favRefs: [Ref] {
        st.favorites.compactMap {
            let p = $0.split(separator: ":").compactMap { Int($0) }
            return p.count == 2 ? Ref(surah: p[0], ayah: p[1]) : nil
        }.sorted { ($0.surah, $0.ayah) < ($1.surah, $1.ayah) }
    }

    var favHadiths: [(String, HadithBook, Hadith)] {
        st.favorites.sorted().compactMap { key in
            let p = key.split(separator: ":").map(String.init)
            guard p.count == 3, p[0] == "h", let n = Int(p[2]), let b = Hadiths.book(p[1]),
                  let h = b.items.first(where: { $0.n == n }) else { return nil }
            return (key, b, h)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("القرآن")
                    .font(.custom("Amiri Quran", size: 26))
                    .foregroundStyle(st.pal.fg)
                Text("Coran")
                    .font(.custom("Inter", size: 13).weight(.semibold))
                    .foregroundStyle(st.pal.muted)
                Spacer()
            }
            .padding(.top, 38).padding(.horizontal, 18).padding(.bottom, 14)

            Button { st.paletteOpen = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 12))
                    Text("Rechercher").font(.custom("Inter", size: 13))
                    Spacer()
                    Text("⌘K").font(.custom("Inter", size: 11)).opacity(0.7)
                }
                .foregroundStyle(st.pal.muted)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(st.pal.card, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(st.pal.line))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14).padding(.bottom, 10)

            if st.mode == .coran, let last = st.lastAyah[st.surahNumber], last > 1, !st.showFavorites {
                Button { Audio.shared.play(.tap); st.open(Ref(surah: st.surahNumber, ayah: last)) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.forward.circle.fill").foregroundStyle(st.accentColor)
                        Text("Reprendre · \(st.surah.en) \(st.surahNumber):\(last)").font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.pal.fg)
                        Spacer()
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(st.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain).padding(.horizontal, 14).padding(.bottom, 8)
            }

            HStack(spacing: 6) {
                Chip(label: "Coran", on: st.mode == .coran && !st.showFavorites, st: st) { st.mode = .coran; st.showFavorites = false }
                Chip(label: "Hadiths", on: st.mode == .hadith && !st.showFavorites, st: st) { st.mode = .hadith; st.showFavorites = false }
                Chip(label: "Arabe", on: st.mode == .learn && !st.showFavorites, st: st) { st.mode = .learn; st.showFavorites = false }
                Chip(label: "★ \(st.favorites.count)", on: st.showFavorites, st: st) { st.showFavorites = true }
            }
            .padding(.horizontal, 14).padding(.bottom, 8)

            if !st.showFavorites && st.mode == .coran {
                TextField("Filtrer les sourates", text: $filter)
                    .textFieldStyle(.plain)
                    .font(.custom("Inter", size: 12))
                    .foregroundStyle(st.pal.fg)
                    .padding(.horizontal, 18).padding(.bottom, 6)
            }

            ScrollView {
                LazyVStack(spacing: 2) {
                    if st.showFavorites {
                        if favRefs.isEmpty && favHadiths.isEmpty {
                            Text(favRefs.isEmpty && favHadiths.isEmpty ? "Touche l'étoile d'un verset ou d'un hadith pour le garder ici." : "")
                                .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                                .padding(18)
                        }
                        ForEach(favRefs, id: \.self) { r in
                            if let s = Quran.surah(r.surah) {
                                Row(title: "\(s.en) \(r.surah):\(r.ayah)", sub: s.ayahs[r.ayah - 1].fr,
                                    selected: false, st: st) { st.open(r) }
                            }
                        }
                        ForEach(favHadiths, id: \.0) { key, b, h in
                            Row(title: "\(b.fr) · \(h.n)", sub: h.fr, selected: false, st: st) { st.openHadith(b.id, h.n) }
                        }
                    } else if st.mode == .learn {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ton parcours est à droite. Une leçon = 2 à 4 minutes, de l'XP, et ta série grimpe si tu reviens demain.")
                                .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                            Text("Astuce : touche « J'ai lu » sous un verset dans le Coran pour gagner de l'XP en lisant.")
                                .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                        }.padding(14)
                    } else if st.mode == .hadith {
                        ForEach(Hadiths.books) { b in
                            Row(title: b.short, sub: "\(b.items.count) hadiths", selected: b.id == st.bookId, st: st) {
                                st.openHadith(b.id, nil)
                            }
                        }
                    } else {
                        ForEach(list) { s in
                            Row(title: "\(s.n). \(s.en)\(st.p.badges.contains("surah\(s.n)") ? "  ✓" : "")", sub: s.ar, selected: s.n == st.surahNumber, st: st,
                                arabicSub: true) { st.openSurah(s.n) }
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.bottom, 12)
            }

            Rectangle().fill(st.pal.line).frame(height: 1)
            Button { Audio.shared.play(.tap); st.showSettings = true } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(st.accentColor)
                        Text(String((st.p.name.first ?? "؟")).uppercased())
                            .font(.custom("Inter", size: 14).weight(.bold))
                            .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                    }.frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(st.p.name.isEmpty ? "Mon profil" : st.p.name)
                            .font(.custom("Inter", size: 13).weight(.semibold)).foregroundStyle(st.pal.fg)
                        HStack(spacing: 8) {
                            Label("\(st.liveStreak)", systemImage: "flame.fill").foregroundStyle(.orange)
                            Label("\(st.p.xp)", systemImage: "bolt.fill").foregroundStyle(Color(hex: 0xFFC83D))
                        }
                        .font(.custom("Inter", size: 11).weight(.semibold)).labelStyle(.titleAndIcon)
                    }
                    Spacer()
                    Ring(progress: st.goalProgress, color: st.accentColor, track: st.pal.line.opacity(2), width: 4)
                        .frame(width: 26, height: 26)
                    Button { Audio.shared.play(.tap); st.showStats = true } label: {
                        Image(systemName: "chart.bar.fill").font(.system(size: 13)).foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain).help("Mes stats")
                    Image(systemName: "gearshape.fill").font(.system(size: 13)).foregroundStyle(st.pal.muted)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(st.pal.bg)
    }
}

struct Chip: View {
    let label: String; let on: Bool; let st: AppState; let action: () -> Void
    var body: some View {
        Button { Audio.shared.play(.tap); action() } label: {
            Text(label).font(.custom("Inter", size: 12).weight(.medium))
                .foregroundStyle(on ? st.pal.bg : st.pal.muted)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(on ? st.pal.fg : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(on ? Color.clear : st.pal.line))
        }.buttonStyle(.plain)
    }
}

struct Row: View {
    let title: String; let sub: String; let selected: Bool; let st: AppState
    var arabicSub = false
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.custom("Inter", size: 13).weight(.medium)).foregroundStyle(st.pal.fg)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if arabicSub {
                    Text(sub).font(.custom("Amiri Quran", size: 16)).foregroundStyle(st.pal.muted).lineLimit(1)
                } else {
                    Text(sub).font(.custom("Inter", size: 11)).foregroundStyle(st.pal.muted).lineLimit(1)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? st.pal.card : (hover ? st.pal.card.opacity(0.6) : .clear),
                        in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

// MARK: - Lecteur

struct Reader: View {
    @Bindable var st: AppState

    var body: some View {
        let s = st.surah
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    SurahHeader(st: st, s: s).id("top")
                    ForEach(s.ayahs) { a in
                        AyahView(st: st, s: s, a: a)
                            .id(a.n)
                            .onAppear { st.lastAyah[s.n] = a.n }
                    }
                    Footer(st: st, s: s)
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
            }
            .id(s.n)
            .onAppear { jump(proxy) }
            .onChange(of: st.scrollTo) { _, _ in jump(proxy) }
            .onChange(of: st.surahNumber) { _, _ in
                DispatchQueue.main.async { jump(proxy) }
            }
            .onChange(of: st.reciter.ayah) { _, a in
                guard st.reciter.surah == s.n, st.reciter.playing else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    if a == 0 { proxy.scrollTo("top", anchor: .top) } else { proxy.scrollTo(a, anchor: .center) }
                }
            }
        }
        .background(st.pal.bg)
        .overlay(alignment: .bottom) {
            PlayerBar(st: st).padding(.bottom, 16).padding(.horizontal, 28)
        }
    }

    func jump(_ proxy: ScrollViewProxy) {
        guard let t = st.scrollTo else { return }
        st.scrollTo = nil
        func go() {
            if t == 1 { proxy.scrollTo("top", anchor: .top) } else { proxy.scrollTo(t, anchor: .top) }
        }
        go()
        // LazyVStack ne connaît pas encore les hauteurs réelles : on corrige après le layout.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { go() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { go() }
    }
}

struct HadithReader: View {
    @Bindable var st: AppState

    var body: some View {
        let book = Hadiths.book(st.bookId) ?? Hadiths.books[0]
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Text(book.ar).font(.custom("Amiri Quran", size: st.arSize * 1.6)).foregroundStyle(st.pal.fg)
                            .environment(\.layoutDirection, .rightToLeft)
                        Text(book.fr).font(.custom("Literata", size: 17).weight(.light)).foregroundStyle(st.pal.muted)
                        Text("\(book.items.count) hadiths")
                            .font(.custom("Inter", size: 11).weight(.medium)).textCase(.uppercase).tracking(1.2)
                            .foregroundStyle(st.pal.muted.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity).padding(.top, 62).padding(.bottom, 30).id("top")
                    ForEach(book.items) { h in
                        HadithView(st: st, book: book, h: h).id(h.n)
                    }
                    Color.clear.frame(height: 50)
                }
                .frame(maxWidth: 760).frame(maxWidth: .infinity).padding(.horizontal, 28)
            }
            .id(book.id)
            .onAppear { jump(proxy) }
            .onChange(of: st.scrollTo) { _, _ in jump(proxy) }
            .onChange(of: st.bookId) { _, _ in DispatchQueue.main.async { jump(proxy) } }
        }
        .background(st.pal.bg)
    }

    func jump(_ proxy: ScrollViewProxy) {
        guard let t = st.scrollTo else { return }
        st.scrollTo = nil
        func go() { if t == 1 && st.highlight == nil { proxy.scrollTo("top", anchor: .top) } else { proxy.scrollTo(t, anchor: .top) } }
        go()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { go() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { go() }
    }
}

struct HadithView: View {
    let st: AppState; let book: HadithBook; let h: Hadith
    @State private var hover = false
    var key: String { "h:\(book.id):\(h.n)" }
    var fav: Bool { st.favorites.contains(key) }
    var lit: Bool { st.highlight == h.n }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    if fav { st.favorites.remove(key) } else { st.favorites.insert(key) }
                } label: {
                    Image(systemName: fav ? "star.fill" : "star").foregroundStyle(fav ? st.pal.accent : st.pal.muted)
                }
                .buttonStyle(.plain).opacity(fav || hover ? 1 : 0).font(.system(size: 12))
                ReadButton(st: st, key: key)
                Spacer()
                Text("Hadith \(h.n)").font(.custom("Inter", size: 11).weight(.medium)).foregroundStyle(st.pal.muted)
            }
            if !h.ar.isEmpty {
                Text("\u{2067}\(h.ar)\u{2069}")
                    .font(.custom("Amiri Quran", size: st.arSize * 0.8))
                    .lineSpacing(st.arSize * 0.3)
                    .foregroundStyle(st.pal.fg)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .textSelection(.enabled)
            }
            if st.showFR && !h.fr.isEmpty {
                Text(h.fr).font(.custom("Literata", size: 16)).lineSpacing(5).foregroundStyle(st.pal.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 20)
        .background(lit ? st.pal.card : (hover ? st.pal.card.opacity(0.4) : .clear), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottom) { Rectangle().fill(st.pal.line).frame(height: 1).padding(.horizontal, 18) }
        .onHover { hover = $0 }
    }
}

struct OldHeader: View {
    let st: AppState; let s: Surah
    var body: some View {
        VStack(spacing: 10) {
            Text("سُورَةُ \(s.ar)")
                .font(.custom("Amiri Quran", size: st.arSize * 1.9))
                .foregroundStyle(st.pal.fg)
                .environment(\.layoutDirection, .rightToLeft)
            Text("\(s.en) · \(s.tr)")
                .font(.custom("Literata", size: 17).weight(.light)).foregroundStyle(st.pal.muted)
            Text("\(s.ayahs.count) versets · \(s.lieu) · sourate \(s.n)")
                .font(.custom("Inter", size: 11).weight(.medium)).textCase(.uppercase).tracking(1.2)
                .foregroundStyle(st.pal.muted.opacity(0.8))
            let here = st.reciter.surah == s.n
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
            }
            .buttonStyle(.plain).padding(.top, 14)
            if s.n != 1 && s.n != 9 {
                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                    .font(.custom("Amiri Quran", size: st.arSize * 1.15))
                    .foregroundStyle(here && st.reciter.ayah == 0 && st.reciter.playing ? st.accentColor : st.pal.fg)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 62).padding(.bottom, 30)
    }
}

struct AyahView: View {
    let st: AppState; let s: Surah; let a: Ayah
    @State private var hover = false

    var ref: Ref { Ref(surah: s.n, ayah: a.n) }
    var fav: Bool { st.favorites.contains(ref.key) }
    var hasInfo: Bool { Meta.hasNotes(s.n, a.n) || !Glossary.forVerse(s.n, a).isEmpty }
    var cur: Bool { st.reciter.surah == s.n && st.reciter.ayah == a.n }
    var lit: Bool { st.highlight == a.n || cur }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 10) {
                    Button { Audio.shared.play(.tap); st.reciter.start(s.n, from: a.n) } label: {
                        Image(systemName: cur && st.reciter.playing ? "waveform" : "play.fill")
                            .foregroundStyle(cur ? st.accentColor : st.pal.muted)
                    }.buttonStyle(.plain).help("Écouter à partir de ce verset")
                    Button { Audio.shared.play(.tap); st.checkRef = ref } label: {
                        Image(systemName: "mic.fill").foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain).help("Je récite ce verset")
                    if hasInfo {
                        Button { Audio.shared.play(.soft); st.info = AppState.InfoTarget(ref: ref, focus: nil) } label: {
                            Image(systemName: Meta.hasNotes(s.n, a.n) ? "info.circle.fill" : "info.circle")
                                .foregroundStyle(Meta.hasNotes(s.n, a.n) ? st.accentColor : st.pal.muted)
                        }.buttonStyle(.plain).help("Contexte et notes sur ce verset")
                    }
                    Button { st.toggleFavorite(ref) } label: {
                        Image(systemName: fav ? "star.fill" : "star")
                            .foregroundStyle(fav ? st.pal.accent : st.pal.muted)
                    }
                    .buttonStyle(.plain)
                    .opacity(fav || hover ? 1 : 0)
                    Button { copy() } label: {
                        Image(systemName: "doc.on.doc").foregroundStyle(st.pal.muted)
                    }
                    .buttonStyle(.plain).opacity(hover ? 1 : 0)
                }
                .font(.system(size: 12))
                ReadButton(st: st, key: "\(s.n):\(a.n)")
                Spacer()
                Text("\(s.n):\(a.n)")
                    .font(.custom("Inter", size: 11).weight(.medium)).foregroundStyle(st.pal.muted)
            }
            Text(followText())
                .environment(\.openURL, OpenURLAction { url in
                    if url.scheme == "coran-gloss" { st.info = AppState.InfoTarget(ref: ref, focus: url.host); return .handled }
                    return .systemAction
                })
                .tint(st.pal.fg)
                .font(.custom("Amiri Quran", size: st.arSize))
                .lineSpacing(st.arSize * 0.7)
                .multilineTextAlignment(.leading)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)
            if st.showGloss, case let g = Glossary.forVerse(s.n, a), !g.isEmpty {
                GlossChips(st: st, ref: ref, entries: g)
            }
            if st.showFR {
                Text(st.verseFR(s.n, a))
                    .font(.custom("Literata", size: 16))
                    .lineSpacing(5)
                    .foregroundStyle(st.pal.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 20)
        .background(lit ? st.pal.card : (hover ? st.pal.card.opacity(0.4) : .clear),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottom) {
            Rectangle().fill(st.pal.line).frame(height: 1).padding(.horizontal, 18)
        }
        .onHover { hover = $0 }
    }

    /// Texte arabe ; pendant l'écoute, les mots déjà récités passent en couleur d'accent.
    func followText() -> AttributedString {
        let words = a.ar.split(separator: " ").map(String.init)
        let progress: Double? = cur ? st.reciter.fraction : nil
        let gloss = st.showGloss ? Glossary.matches(ref: "\(s.n):\(a.n)", words: words) : []
        let weights = words.map { Double($0.count + 1) }
        let total = max(1, weights.reduce(0, +))
        var out = AttributedString("\u{2067}")
        var acc = 0.0
        for (i, w) in words.enumerated() {
            var part = AttributedString(w + " ")
            let reached = progress.map { (acc + weights[i] * 0.35) / total <= $0 } ?? false
            part.foregroundColor = reached ? st.accentColor : st.pal.fg
            if i < gloss.count, let g = gloss[i] { part.link = URL(string: "coran-gloss://\(g.id)") }
            out += part
            acc += weights[i]
        }
        var tail = AttributedString("\u{FD3F}\(arabicDigits(a.n))\u{FD3E}\u{2069}")
        tail.foregroundColor = st.pal.fg
        out += tail
        return out
    }

    func copy() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("\(a.ar)\n\(a.fr)\n(\(s.en) \(s.n):\(a.n))", forType: .string)
    }
}

struct Footer: View {
    let st: AppState; let s: Surah
    var body: some View {
        HStack {
            if let p = Quran.surah(s.n - 1) {
                Button("← \(p.en)") { st.openSurah(p.n) }
            }
            Spacer()
            if let n = Quran.surah(s.n + 1) {
                Button("\(n.en) →") { st.openSurah(n.n) }
            }
        }
        .buttonStyle(.plain)
        .font(.custom("Inter", size: 13).weight(.medium))
        .foregroundStyle(st.pal.accent)
        .padding(.vertical, 50)
    }
}

// MARK: - Palette ⌘K

struct PaletteView: View {
    @Bindable var st: AppState
    @State private var query = ""
    @State private var sel = 0
    @FocusState private var focus: Bool

    var hits: [Hit] { Search.run(query, favorites: st.favorites) }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(st.theme == .dark ? 0.55 : 0.25)
                .ignoresSafeArea()
                .onTapGesture { st.paletteOpen = false }
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(st.pal.muted)
                    TextField("Sourate, 2:255, ou un mot (« patience », « miséricorde »)", text: $query)
                        .textFieldStyle(.plain)
                        .font(.custom("Inter", size: 16))
                        .foregroundStyle(st.pal.fg)
                        .focused($focus)
                        .onSubmit { go(sel) }
                    Text("esc").font(.custom("Inter", size: 11)).foregroundStyle(st.pal.muted)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(st.pal.line))
                }
                .padding(16)
                Rectangle().fill(st.pal.line).frame(height: 1)
                let h = hits
                ScrollView {
                    VStack(spacing: 2) {
                        if h.isEmpty {
                            Text(query.isEmpty ? "Tape pour chercher. Tes favoris apparaissent ici." : "Aucun résultat")
                                .font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted).padding(24)
                        }
                        ForEach(Array(h.enumerated()), id: \.element.id) { i, hit in
                            HitRow(st: st, hit: hit, selected: i == sel)
                                .onTapGesture { go(i) }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 380)
            }
            .frame(width: 600)
            .background(st.pal.bg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(st.pal.line.opacity(2)))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 16)
            .padding(.top, 90)
        }
        .onAppear { focus = true; query = ""; sel = 0 }
        .onChange(of: query) { _, _ in sel = 0 }
        .onKeyPress(.downArrow) { sel = min(sel + 1, max(0, hits.count - 1)); return .handled }
        .onKeyPress(.upArrow) { sel = max(sel - 1, 0); return .handled }
        .onExitCommand { st.paletteOpen = false }
    }

    func go(_ i: Int) {
        let h = hits
        guard h.indices.contains(i) else { return }
        switch h[i].kind {
        case .surah(let n): st.openSurah(n)
        case .ayah(let r): st.open(r)
        case .hadith(let b, let n): st.openHadith(b, n)
        }
    }
}

struct HitRow: View {
    let st: AppState; let hit: Hit; let selected: Bool
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(hit.title).font(.custom("Inter", size: 13).weight(.semibold)).foregroundStyle(st.pal.fg)
                Text(hit.subtitle).font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted).lineLimit(2)
            }
            Spacer()
            if !hit.arabic.isEmpty {
                Text(hit.arabic).font(.custom("Amiri Quran", size: 20)).foregroundStyle(st.pal.muted)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? st.pal.card : .clear, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }
}


struct ReadButton: View {
    let st: AppState; let key: String
    var body: some View {
        let on = st.isRead(key)
        Button { st.toggleRead(key) } label: {
            HStack(spacing: 5) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                Text(on ? "Lu" : "J'ai lu · +5")
            }
            .font(.custom("Inter", size: 11).weight(.semibold))
            .foregroundStyle(on ? st.accentColor : st.pal.muted)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .overlay(Capsule().stroke(on ? st.accentColor.opacity(0.6) : st.pal.line.opacity(2)))
        }
        .buttonStyle(.plain)
    }
}


struct PlayerBar: View {
    @Bindable var st: AppState

    var body: some View {
        if let sn = st.reciter.surah, let s = Quran.surah(sn) {
            let r = st.reciter
            HStack(spacing: 14) {
                Button { st.openSurah(sn) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.en).font(.custom("Inter", size: 13).weight(.bold)).foregroundStyle(st.pal.fg)
                        Text(r.ayah == 0 ? "Basmala" : "Verset \(r.ayah)/\(s.ayahs.count) · \(r.reciterName)")
                            .font(.custom("Inter", size: 11)).foregroundStyle(st.pal.muted).lineLimit(1)
                    }
                }.buttonStyle(.plain)
                Spacer()
                Button { r.previous() } label: { Image(systemName: "backward.fill") }.buttonStyle(.plain)
                Button { r.toggle() } label: {
                    Image(systemName: r.playing ? "pause.fill" : "play.fill").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                        .frame(width: 40, height: 40).background(st.accentColor, in: Circle())
                }.buttonStyle(.plain)
                Button { r.next() } label: { Image(systemName: "forward.fill") }.buttonStyle(.plain)
                Button { r.repeatVerse.toggle(); Audio.shared.play(.tap) } label: {
                    Image(systemName: "repeat.1").foregroundStyle(r.repeatVerse ? st.accentColor : st.pal.muted)
                }.buttonStyle(.plain).help("Répéter le verset (pour mémoriser)")
                Menu {
                    ForEach([0.75, 1.0, 1.25], id: \.self) { v in Button("\(v == 1 ? "Normale" : String(format: "%.2fx", v))") { r.speed = v } }
                } label: { Text(r.speed == 1 ? "1x" : String(format: "%.2gx", r.speed)).font(.custom("Inter", size: 12).weight(.semibold)) }
                    .menuStyle(.borderlessButton).fixedSize()
                Menu {
                    ForEach(reciters, id: \.id) { x in
                        Button(x.name) { let was = r.playing; r.reciterId = x.id; if was, let sn = r.surah { r.start(sn, from: max(1, r.ayah)) } }
                    }
                } label: { Image(systemName: "person.wave.2.fill") }.menuStyle(.borderlessButton).fixedSize().help("Changer de récitant")
                Button { r.stop() } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            .font(.system(size: 14)).foregroundStyle(st.pal.fg)
            .padding(.horizontal, 18).padding(.vertical, 10)
            .frame(maxWidth: 720)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .background(st.pal.card.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(st.pal.line.opacity(2)))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(duration: 0.35), value: r.surah)
        }
    }
}
