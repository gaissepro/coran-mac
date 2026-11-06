import SwiftUI

struct Choice: View {
    let st: AppState; let title: String; let sub: String; let on: Bool; let action: () -> Void
    var body: some View {
        Button { Audio.shared.play(.tap); action() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.custom("Inter", size: 15).weight(.semibold)).foregroundStyle(st.pal.fg)
                    Text(sub).font(.custom("Inter", size: 12)).foregroundStyle(st.pal.muted)
                }
                Spacer()
                if on { Image(systemName: "checkmark.circle.fill").foregroundStyle(st.accentColor) }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(on ? st.accentColor.opacity(0.12) : st.pal.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(on ? st.accentColor : st.pal.line, lineWidth: on ? 2 : 1))
        }.buttonStyle(.plain)
    }
}

struct AccentPicker: View {
    @Bindable var st: AppState
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(accents.enumerated()), id: \.offset) { i, a in
                Button { Audio.shared.play(.tap); st.p.accent = i } label: {
                    Circle().fill(Color(hex: a.hex)).frame(width: 34, height: 34)
                        .overlay(Circle().stroke(st.pal.fg, lineWidth: st.p.accent == i ? 3 : 0).padding(-4))
                }.buttonStyle(.plain).help(a.name)
            }
        }
    }
}

struct ThemePicker: View {
    @Bindable var st: AppState
    var body: some View {
        HStack(spacing: 10) {
            ForEach(ThemeKind.allCases, id: \.self) { t in
                let pp = Palette.of(t, accent: st.accentColor)
                Button { Audio.shared.play(.tap); st.theme = t } label: {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10).fill(pp.bg).frame(width: 74, height: 46)
                            .overlay(Text("ب").font(.custom("Amiri Quran", size: 24)).foregroundStyle(pp.fg))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(st.theme == t ? st.accentColor : st.pal.line.opacity(2), lineWidth: st.theme == t ? 3 : 1))
                        Text(t.label).font(.custom("Inter", size: 11).weight(.medium)).foregroundStyle(st.pal.muted)
                    }
                }.buttonStyle(.plain)
            }
        }
    }
}

struct Onboarding: View {
    @Bindable var st: AppState
    @State private var step = 0
    @FocusState private var focus: Bool
    private let steps = 5

    var body: some View {
        ZStack {
            st.pal.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<steps, id: \.self) { i in
                        Capsule().fill(i <= step ? st.accentColor : st.pal.card).frame(height: 6)
                    }
                }
                .padding(.horizontal, 60).padding(.top, 46)
                .animation(.spring(duration: 0.4), value: step)

                Spacer()
                content
                    .frame(maxWidth: 520)
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                Spacer()

                HStack {
                    if step > 0 {
                        Button("Retour") { Audio.shared.play(.soft); withAnimation { step -= 1 } }
                            .buttonStyle(.plain).foregroundStyle(st.pal.muted).font(.custom("Inter", size: 14).weight(.medium))
                    }
                    Spacer()
                    Button { next() } label: {
                        Text(step == steps - 1 ? "C'est parti" : "Continuer")
                            .font(.custom("Inter", size: 15).weight(.bold))
                            .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                            .padding(.horizontal, 36).padding(.vertical, 13)
                            .background(st.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(step == 1 && st.p.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(step == 1 && st.p.name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 60).padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    func next() {
        Audio.shared.play(.tap)
        if step == steps - 1 {
            st.p.name = st.p.name.trimmingCharacters(in: .whitespaces)
            st.p.onboarded = true
            Audio.shared.play(.done)
            st.confetti += 1
            st.showToast("Bienvenue \(st.p.name) !")
            return
        }
        withAnimation { step += 1 }
    }

    @ViewBuilder var content: some View {
        switch step {
        case 0:
            VStack(spacing: 18) {
                Text("القرآن").font(.custom("Amiri Quran", size: 96)).foregroundStyle(st.pal.fg)
                Text("Bienvenue").font(.custom("Literata", size: 34).weight(.semibold)).foregroundStyle(st.pal.fg)
                Text("Lis, apprends, reviens chaque jour. On configure ton espace en 4 questions.")
                    .font(.custom("Inter", size: 15)).foregroundStyle(st.pal.muted).multilineTextAlignment(.center)
            }
        case 1:
            VStack(spacing: 18) {
                Text("Comment t'appelles-tu ?").font(.custom("Literata", size: 28).weight(.semibold)).foregroundStyle(st.pal.fg)
                TextField("Ton prénom", text: $st.p.name)
                    .textFieldStyle(.plain).font(.custom("Inter", size: 20)).foregroundStyle(st.pal.fg)
                    .multilineTextAlignment(.center)
                    .padding(16).background(st.pal.card, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(st.accentColor.opacity(0.6)))
                    .focused($focus)
                    .onSubmit { if !st.p.name.trimmingCharacters(in: .whitespaces).isEmpty { next() } }
                    .onAppear { focus = true }
            }
        case 2:
            VStack(spacing: 12) {
                Text("Ton niveau en arabe ?").font(.custom("Literata", size: 28).weight(.semibold)).foregroundStyle(st.pal.fg).padding(.bottom, 8)
                Choice(st: st, title: "Je pars de zéro", sub: "Je ne connais pas encore les lettres", on: st.p.level == "debutant") { st.p.level = "debutant" }
                Choice(st: st, title: "Je lis lentement", sub: "Je connais les lettres, je déchiffre", on: st.p.level == "base") { st.p.level = "base" }
                Choice(st: st, title: "Je lis déjà bien", sub: "Je veux surtout comprendre et mémoriser", on: st.p.level == "avance") { st.p.level = "avance" }
            }
        case 3:
            VStack(spacing: 12) {
                Text("Ton objectif quotidien").font(.custom("Literata", size: 28).weight(.semibold)).foregroundStyle(st.pal.fg).padding(.bottom, 8)
                Choice(st: st, title: "Tranquille · 15 XP", sub: "environ 3 minutes par jour", on: st.p.goalXP == 15) { st.p.goalXP = 15 }
                Choice(st: st, title: "Régulier · 30 XP", sub: "environ 7 minutes par jour", on: st.p.goalXP == 30) { st.p.goalXP = 30 }
                Choice(st: st, title: "Sérieux · 60 XP", sub: "environ 15 minutes par jour", on: st.p.goalXP == 60) { st.p.goalXP = 60 }
                Choice(st: st, title: "Intense · 100 XP", sub: "environ 25 minutes par jour", on: st.p.goalXP == 100) { st.p.goalXP = 100 }
            }
        default:
            VStack(spacing: 22) {
                Text("À ton goût").font(.custom("Literata", size: 28).weight(.semibold)).foregroundStyle(st.pal.fg)
                VStack(spacing: 10) {
                    Text("Couleur").font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.pal.muted)
                    AccentPicker(st: st)
                }
                VStack(spacing: 10) {
                    Text("Thème").font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.pal.muted)
                    ThemePicker(st: st)
                }
                VStack(spacing: 10) {
                    Text("Ce que tu veux faire surtout").font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.pal.muted)
                    HStack(spacing: 8) {
                        Chip(label: "Lire et comprendre", on: st.p.intent == "lire", st: st) { st.p.intent = "lire" }
                        Chip(label: "Apprendre l'arabe", on: st.p.intent == "arabe", st: st) { st.p.intent = "arabe" }
                        Chip(label: "Mémoriser", on: st.p.intent == "memoriser", st: st) { st.p.intent = "memoriser" }
                    }
                }
            }
        }
    }
}

// MARK: - Paramètres

struct SettingsView: View {
    @Bindable var st: AppState
    @State private var confirmReset = false

    func section(_ t: String) -> some View {
        Text(t).font(.custom("Inter", size: 11).weight(.bold)).tracking(1.2).textCase(.uppercase)
            .foregroundStyle(st.pal.muted).padding(.top, 8)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(st.theme == .dark ? 0.6 : 0.3).ignoresSafeArea()
                .onTapGesture { st.showSettings = false }
            VStack(spacing: 0) {
                HStack {
                    Text("Paramètres").font(.custom("Literata", size: 22).weight(.semibold)).foregroundStyle(st.pal.fg)
                    Spacer()
                    Button { Audio.shared.play(.tap); st.showSettings = false } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.vertical, 18)
                Rectangle().fill(st.pal.line).frame(height: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        section("Profil")
                        TextField("Prénom", text: $st.p.name).textFieldStyle(.plain)
                            .font(.custom("Inter", size: 15)).foregroundStyle(st.pal.fg)
                            .padding(12).background(st.pal.card, in: RoundedRectangle(cornerRadius: 12))
                        HStack(spacing: 8) {
                            Chip(label: "Débutant", on: st.p.level == "debutant", st: st) { st.p.level = "debutant" }
                            Chip(label: "Lecteur lent", on: st.p.level == "base", st: st) { st.p.level = "base" }
                            Chip(label: "Lecteur confirmé", on: st.p.level == "avance", st: st) { st.p.level = "avance" }
                        }

                        section("Objectif du jour")
                        HStack(spacing: 8) {
                            ForEach([15, 30, 60, 100], id: \.self) { g in
                                Chip(label: "\(g) XP", on: st.p.goalXP == g, st: st) { Audio.shared.play(.tap); st.p.goalXP = g }
                            }
                        }

                        section("Apparence")
                        AccentPicker(st: st)
                        ThemePicker(st: st)
                        HStack {
                            Text("Taille de l'arabe").font(.custom("Inter", size: 14)).foregroundStyle(st.pal.fg)
                            Slider(value: $st.arSize, in: 22...72, step: 2).tint(st.accentColor)
                            Text("\(Int(st.arSize))").font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted).frame(width: 28)
                        }
                        Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ").font(.custom("Amiri Quran", size: st.arSize))
                            .foregroundStyle(st.pal.fg).frame(maxWidth: .infinity, alignment: .center)
                        Toggle("Afficher la traduction française", isOn: $st.showFR).tint(st.accentColor)
                        HStack(spacing: 8) {
                            Text("Traduction").font(.custom("Inter", size: 14)).foregroundStyle(st.pal.fg)
                            Spacer()
                            Chip(label: "Hamidullah", on: st.translation == "hamidullah", st: st) { st.translation = "hamidullah" }
                            Chip(label: "Montada (avec notes)", on: st.translation == "montada", st: st) { st.translation = "montada" }
                        }
                        Toggle("Souligner et expliquer les mots importants", isOn: $st.showGloss).tint(st.accentColor)

                        section("Sons")
                        Toggle("Sons de l'interface", isOn: $st.p.sound).tint(st.accentColor)
                        Toggle("Voix arabe dans les leçons", isOn: $st.p.voice).tint(st.accentColor)
                        Button { Audio.shared.speak("بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ") } label: {
                            Label("Tester la voix", systemImage: "speaker.wave.2.fill").font(.custom("Inter", size: 13).weight(.medium))
                        }.buttonStyle(.plain).foregroundStyle(st.accentColor)

                        section("Statistiques")
                        HStack(spacing: 10) {
                            StatPill(st: st, symbol: "bolt.fill", color: Color(hex: 0xFFC83D), value: "\(st.p.xp)", label: "XP total")
                            StatPill(st: st, symbol: "flame.fill", color: .orange, value: "\(st.p.bestStreak)", label: "meilleure série")
                            StatPill(st: st, symbol: "book.fill", color: st.accentColor, value: "\(st.p.read.count)", label: "versets lus")
                        }
                        section("Badges")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                            ForEach(badgeInfo, id: \.id) { b in
                                let on = st.p.badges.contains(b.id)
                                HStack(spacing: 10) {
                                    Image(systemName: b.symbol).font(.system(size: 18)).foregroundStyle(on ? Color(hex: 0xFFC83D) : st.pal.muted.opacity(0.5))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(b.title).font(.custom("Inter", size: 12).weight(.semibold)).foregroundStyle(on ? st.pal.fg : st.pal.muted)
                                        Text(b.desc).font(.custom("Inter", size: 10)).foregroundStyle(st.pal.muted).lineLimit(2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                .background(st.pal.card.opacity(on ? 1 : 0.5), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        section("Données")
                        HStack {
                            Button("Refaire l'inscription") { st.showSettings = false; st.p.onboarded = false }
                                .buttonStyle(.plain).foregroundStyle(st.accentColor)
                            Spacer()
                            Button(confirmReset ? "Confirmer : tout remettre à zéro" : "Réinitialiser ma progression") {
                                if confirmReset { st.resetProgress(); confirmReset = false; st.showToast("Progression remise à zéro") }
                                else { confirmReset = true }
                            }
                            .buttonStyle(.plain).foregroundStyle(Palette.bad)
                        }
                        .font(.custom("Inter", size: 13).weight(.medium))
                    }
                    .padding(24)
                }
            }
            .frame(width: 620, height: 640)
            .background(st.pal.bg, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(st.pal.line.opacity(2)))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 16)
        }
        .onExitCommand { st.showSettings = false }
    }
}
