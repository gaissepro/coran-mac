import SwiftUI

// MARK: - Accueil « Apprendre »

struct StatPill: View {
    let st: AppState; let symbol: String; let color: Color; let value: String; let label: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.custom("Inter", size: 18).weight(.bold)).foregroundStyle(st.pal.fg)
                Text(label).font(.custom("Inter", size: 11)).foregroundStyle(st.pal.muted)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.pal.line))
    }
}

struct LearnHome: View {
    @Bindable var st: AppState

    var firstTodo: Int { Curriculum.all.firstIndex { !st.p.done.contains($0.id) } ?? Curriculum.all.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(st.p.name.isEmpty ? "Apprendre l'arabe" : "Salam \(st.p.name) 👋")
                        .font(.custom("Literata", size: 30).weight(.semibold)).foregroundStyle(st.pal.fg)
                    Text("Quelques minutes par jour. Chaque leçon rapporte de l'XP, la série monte si tu reviens demain.")
                        .font(.custom("Inter", size: 14)).foregroundStyle(st.pal.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 56)

                HStack(spacing: 12) {
                    StatPill(st: st, symbol: "flame.fill", color: .orange, value: "\(st.liveStreak)", label: "jours de suite")
                    StatPill(st: st, symbol: "bolt.fill", color: Color(hex: 0xFFC83D), value: "\(st.p.xp)", label: "XP · niveau \(st.level)")
                    HStack(spacing: 12) {
                        Ring(progress: st.goalProgress, color: st.accentColor, track: st.pal.line.opacity(2), width: 6)
                            .frame(width: 38, height: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(st.todayXP)/\(st.p.goalXP)").font(.custom("Inter", size: 18).weight(.bold))
                                .foregroundStyle(st.pal.fg)
                            Text("objectif du jour").font(.custom("Inter", size: 11)).foregroundStyle(st.pal.muted)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.pal.line))
                }

                if !st.learnedKeys().isEmpty {
                    Button {
                        if let l = st.reviewLesson() { Audio.shared.play(.tap); st.lesson = l }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 22, weight: .bold))
                                .foregroundStyle(st.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Révision du jour").font(.custom("Inter", size: 15).weight(.bold)).foregroundStyle(st.pal.fg)
                                Text(st.weakCount > 0 ? "\(st.weakCount) élément\(st.weakCount > 1 ? "s" : "") à retenir · +10 XP"
                                                      : "Rafraîchis ce que tu as appris pour ne pas l'oublier · +10 XP")
                                    .font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(st.pal.muted)
                        }
                        .padding(16)
                        .background(st.pal.card, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(st.accentColor.opacity(0.5), lineWidth: 1.5))
                    }.buttonStyle(.plain)
                }

                ForEach(Curriculum.units) { u in
                    UnitView(st: st, unit: u, firstTodo: firstTodo)
                }
                Color.clear.frame(height: 40)
            }
            .frame(maxWidth: 680).frame(maxWidth: .infinity).padding(.horizontal, 28)
        }
        .background(st.pal.bg)
    }
}

struct UnitView: View {
    let st: AppState; let unit: Unit; let firstTodo: Int

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text(unit.title).font(.custom("Inter", size: 15).weight(.bold)).foregroundStyle(st.pal.bg)
                Text(unit.subtitle).font(.custom("Inter", size: 12)).foregroundStyle(st.pal.bg.opacity(0.75))
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(st.accentColor, in: RoundedRectangle(cornerRadius: 16))

            ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { i, l in
                let g = Curriculum.all.firstIndex { $0.id == l.id } ?? 0
                LessonNode(st: st, lesson: l, done: st.p.done.contains(l.id), current: g == firstTodo, locked: g > firstTodo)
                    .offset(x: CGFloat(sin(Double(i) * 1.1) * 70))
            }
        }
    }
}

struct LessonNode: View {
    let st: AppState; let lesson: Lesson; let done: Bool; let current: Bool; let locked: Bool
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                guard !locked else { Audio.shared.play(.bad); st.showToast("Termine d'abord la leçon précédente"); return }
                Audio.shared.play(.tap)
                st.lesson = lesson
            } label: {
                ZStack {
                    if current {
                        Circle().stroke(st.accentColor.opacity(0.5), lineWidth: 4)
                            .frame(width: 96, height: 96)
                            .scaleEffect(pulse ? 1.08 : 0.96).opacity(pulse ? 0.3 : 0.9)
                    }
                    Circle()
                        .fill(locked ? st.pal.card : (done ? Color(hex: 0xFFC83D) : st.accentColor))
                        .frame(width: 78, height: 78)
                        .overlay(Circle().stroke(st.pal.line, lineWidth: locked ? 1 : 0))
                        .shadow(color: (locked ? Color.clear : (done ? Color(hex: 0xFFC83D) : st.accentColor)).opacity(0.35), radius: 10, y: 5)
                    Image(systemName: locked ? "lock.fill" : (done ? "checkmark" : lesson.symbol))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(locked ? st.pal.muted : (st.pal.scheme == .dark ? Color.black : Color.white))
                }
            }
            .buttonStyle(.plain)
            Text(lesson.title)
                .font(lesson.title.unicodeScalars.contains { $0.value > 0x600 } ? .custom("Amiri Quran", size: 20) : .custom("Inter", size: 12).weight(.semibold))
                .foregroundStyle(locked ? st.pal.muted : st.pal.fg)
            if current {
                Text("COMMENCER").font(.custom("Inter", size: 10).weight(.bold)).tracking(1.2)
                    .foregroundStyle(st.accentColor)
            }
        }
        .onAppear { if current { withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true } } }
    }
}

// MARK: - Leçon

struct LessonView: View {
    @Bindable var st: AppState
    let lesson: Lesson

    enum Phase { case answering, right, wrong }

    @State private var queue: [Question] = []
    @State private var total = 1
    @State private var mistakes = 0
    @State private var phase: Phase = .answering
    @State private var selected: Int? = nil
    @State private var picked: [Int] = []
    @State private var finished = false
    @State private var rewarded = false
    @State private var heard = ""

    var q: Question? { queue.first }
    var progress: Double { finished ? 1 : Double(total - queue.count) / Double(max(1, total)) }
    var canCheck: Bool {
        guard let q else { return false }
        if q.speakCheck { return false }
        return q.isOrder ? picked.count == q.tiles.count : selected != nil
    }

    var body: some View {
        ZStack {
            st.pal.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button { Audio.shared.play(.tap); st.lesson = nil } label: {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(st.pal.card)
                            Capsule().fill(st.accentColor).frame(width: max(14, g.size.width * progress))
                                .animation(.spring(duration: 0.45), value: progress)
                        }
                    }.frame(height: 14)
                }
                .padding(.horizontal, 32).padding(.top, 42).padding(.bottom, 8)

                if finished {
                    Finish(st: st, lesson: lesson, mistakes: mistakes)
                } else if let q {
                    VStack(spacing: 22) {
                        Spacer(minLength: 10)
                        Text(q.prompt).font(.custom("Inter", size: 22).weight(.bold)).foregroundStyle(st.pal.fg)
                            .multilineTextAlignment(.center)
                        if let h = q.hint, st.showFR {
                            Text(h).font(.custom("Literata", size: 15)).foregroundStyle(st.pal.muted)
                                .multilineTextAlignment(.center).frame(maxWidth: 560)
                        }
                        HStack(spacing: 14) {
                            if let b = q.big {
                                Text(b).font(.custom("Amiri Quran", size: 64)).foregroundStyle(st.pal.fg)
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                            if let s = q.speak {
                                Button { Audio.shared.speak(s) } label: {
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 20))
                                        .foregroundStyle(st.accentColor)
                                        .frame(width: 54, height: 54)
                                        .background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.accentColor.opacity(0.5)))
                                }.buttonStyle(.plain)
                            }
                        }
                        if q.isOrder { OrderArea(st: st, q: q, picked: $picked, locked: phase != .answering) }
                        else if q.speakCheck {
                            if phase == .answering {
                                MicCard(st: st, expected: q.expected) { ratio, _, h in micDone(ratio, h, q) }
                            }
                        }
                        else { Options(st: st, q: q, selected: $selected, phase: phase) }
                        Spacer(minLength: 10)
                    }
                    .padding(.horizontal, 32)
                    .id(q.id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                }

                if !finished, let q { Bottom(q) }
            }
        }
        .onAppear { start() }
        .onKeyPress(.return) { primary(); return .handled }
        .onKeyPress(characters: .decimalDigits) { k in
            guard phase == .answering, let q, !q.isOrder, let n = Int(k.characters), n >= 1, n <= q.options.count else { return .ignored }
            selected = n - 1; Audio.shared.play(.tap); return .handled
        }
        .onExitCommand { st.lesson = nil }
    }

    @ViewBuilder func Bottom(_ q: Question) -> some View {
        let tint: Color = phase == .right ? Palette.good : Palette.bad
        VStack(spacing: 0) {
            Rectangle().fill(st.pal.line).frame(height: 1)
            HStack(spacing: 16) {
                if phase != .answering {
                    Image(systemName: phase == .right ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 32)).foregroundStyle(tint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(phase == .right ? ["Bravo !", "Excellent !", "Mashallah !", "Parfait !"].randomElement()! : "Pas tout à fait")
                            .font(.custom("Inter", size: 18).weight(.bold)).foregroundStyle(tint)
                        Text(q.speakCheck && !heard.isEmpty ? "J'ai entendu : « \(heard) ». \(q.explain)" : q.explain)
                            .font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted).lineLimit(3)
                    }
                }
                Spacer()
                if q.speakCheck && phase == .answering {
                    Button { skip() } label: {
                        Text("Passer").font(.custom("Inter", size: 14).weight(.semibold)).foregroundStyle(st.pal.muted)
                            .padding(.horizontal, 24).padding(.vertical, 13)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.pal.line.opacity(2)))
                    }.buttonStyle(.plain)
                } else {
                Button { primary() } label: {
                    Text(phase == .answering ? "Vérifier" : "Continuer")
                        .font(.custom("Inter", size: 15).weight(.bold))
                        .foregroundStyle(canCheck || phase != .answering ? (st.pal.scheme == .dark ? Color.black : Color.white) : st.pal.muted)
                        .padding(.horizontal, 34).padding(.vertical, 13)
                        .background(phase == .answering ? (canCheck ? st.accentColor : st.pal.card) : tint,
                                    in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(phase == .answering && !canCheck)
                }
            }
            .padding(.horizontal, 32).padding(.vertical, 18)
            .background(phase == .answering ? Color.clear : tint.opacity(0.12))
        }
    }

    func micDone(_ ratio: Double, _ h: String, _ q: Question) {
        let ok = ratio >= 0.6
        heard = h
        phase = ok ? .right : .wrong
        if !ok { mistakes += 1; Audio.shared.play(.bad); Audio.shared.speak(q.expected) } else { Audio.shared.play(.ok) }
        st.recordResult(q.key, ok: ok)
    }

    func skip() {
        Audio.shared.play(.soft)
        withAnimation(.easeInOut(duration: 0.25)) {
            queue.removeFirst()
            phase = .answering; selected = nil; picked = []; heard = ""
            if queue.isEmpty {
                finished = true
                if !rewarded { rewarded = true; Audio.shared.play(.done); st.confetti += 1; st.completeLesson(lesson, mistakes: mistakes) }
            }
        }
    }

    func start() {
        queue = lesson.make()
        total = max(1, queue.count)
        if queue.isEmpty { finished = true } else { autoSpeak() }
    }

    func autoSpeak() {
        if let q = queue.first, let s = q.speak, q.big == nil || !q.isOrder { Audio.shared.speak(s) }
    }

    func primary() {
        guard let q else { if finished { return }; return }
        if phase == .answering {
            guard canCheck else { return }
            let ok = q.isOrder ? picked.map { q.tiles[$0] } == q.correct : selected == q.answer
            phase = ok ? .right : .wrong
            if !ok { mistakes += 1 }
            st.recordResult(q.key, ok: ok)
            Audio.shared.play(ok ? .ok : .bad)
            if ok, q.isOrder, let s = q.speak { Audio.shared.speak(s) }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                if phase == .right { queue.removeFirst() } else { queue.append(queue.removeFirst()) }
                phase = .answering; selected = nil; picked = []; heard = ""
                if queue.isEmpty {
                    finished = true
                    if !rewarded { rewarded = true; Audio.shared.play(.done); st.confetti += 1; st.completeLesson(lesson, mistakes: mistakes) }
                }
            }
            if !finished { autoSpeak() }
        }
    }
}

struct Options: View {
    let st: AppState; let q: Question
    @Binding var selected: Int?
    let phase: LessonView.Phase

    var body: some View {
        let cols = q.optionsArabic ? 2 : 1
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: cols), spacing: 12) {
            ForEach(Array(q.options.enumerated()), id: \.offset) { i, o in
                let sel = selected == i
                let isAnswer = i == q.answer
                let border: Color = phase == .answering ? (sel ? st.accentColor : st.pal.line.opacity(2.2))
                    : (isAnswer ? Palette.good : (sel ? Palette.bad : st.pal.line))
                Button {
                    guard phase == .answering else { return }
                    selected = i; Audio.shared.play(.tap)
                    if q.optionsArabic { Audio.shared.speak(o) }
                } label: {
                    HStack {
                        Text("\(i + 1)").font(.custom("Inter", size: 11).weight(.bold)).foregroundStyle(st.pal.muted)
                            .frame(width: 24, height: 24).overlay(RoundedRectangle(cornerRadius: 6).stroke(st.pal.line.opacity(2)))
                        Spacer()
                        Text(o).font(q.optionsArabic ? .custom("Amiri Quran", size: 34) : .custom("Inter", size: 17).weight(.medium))
                            .foregroundStyle(st.pal.fg)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, q.optionsArabic ? 12 : 15)
                    .background((sel ? border.opacity(0.12) : st.pal.card), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: sel || (phase != .answering && isAnswer) ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 560)
    }
}

struct OrderArea: View {
    let st: AppState; let q: Question
    @Binding var picked: [Int]
    let locked: Bool

    func tile(_ i: Int, _ on: Bool) -> some View {
        Text(q.tiles[i]).font(.custom("Amiri Quran", size: 28)).foregroundStyle(st.pal.fg)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(st.pal.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? st.accentColor.opacity(0.7) : st.pal.line.opacity(2)))
    }

    var body: some View {
        VStack(spacing: 22) {
            Flow(spacing: 10, rtl: true) {
                ForEach(picked, id: \.self) { i in
                    Button { guard !locked else { return }; Audio.shared.play(.soft); picked.removeAll { $0 == i } } label: { tile(i, true) }
                        .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .topTrailing)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).stroke(st.pal.line.opacity(2), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            Flow(spacing: 10, rtl: true) {
                ForEach(0..<q.tiles.count, id: \.self) { i in
                    Button {
                        guard !locked, !picked.contains(i) else { return }
                        Audio.shared.play(.tap); picked.append(i)
                    } label: { tile(i, false).opacity(picked.contains(i) ? 0.18 : 1) }
                        .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: 620)
    }
}

struct Finish: View {
    let st: AppState; let lesson: Lesson; let mistakes: Int
    @State private var pop = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: mistakes == 0 ? "star.circle.fill" : "checkmark.seal.fill")
                .font(.system(size: 84)).foregroundStyle(Color(hex: 0xFFC83D))
                .scaleEffect(pop ? 1 : 0.2)
            Text(mistakes == 0 ? "Leçon parfaite !" : "Leçon terminée !")
                .font(.custom("Literata", size: 32).weight(.semibold)).foregroundStyle(st.pal.fg)
            HStack(spacing: 12) {
                Pill(st: st, symbol: "bolt.fill", color: Color(hex: 0xFFC83D), text: "+\(lesson.xp + (mistakes == 0 ? 5 : 0)) XP")
                Pill(st: st, symbol: "flame.fill", color: .orange, text: "\(st.liveStreak) jours")
                Pill(st: st, symbol: "target", color: st.accentColor, text: mistakes == 0 ? "Sans faute" : "\(mistakes) erreur\(mistakes > 1 ? "s" : "")")
            }
            Button { Audio.shared.play(.tap); st.lesson = nil } label: {
                Text("Terminer").font(.custom("Inter", size: 15).weight(.bold))
                    .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                    .padding(.horizontal, 44).padding(.vertical, 14)
                    .background(st.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }.buttonStyle(.plain).padding(.top, 10)
            Spacer()
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true } }
    }
}

struct Pill: View {
    let st: AppState; let symbol: String; let color: Color; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(text).font(.custom("Inter", size: 14).weight(.bold)).foregroundStyle(st.pal.fg)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(st.pal.card, in: Capsule()).overlay(Capsule().stroke(st.pal.line))
    }
}
