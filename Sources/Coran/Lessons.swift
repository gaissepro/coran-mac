import Foundation

struct Question: Identifiable {
    let id = UUID()
    var prompt: String
    var big: String? = nil          // texte arabe affiché en grand
    var speak: String? = nil        // texte lu à voix haute
    var options: [String] = []
    var answer = 0
    var optionsArabic = false
    var tiles: [String] = []        // pour les exercices d'ordre
    var correct: [String] = []
    var hint: String? = nil
    var explain: String = ""
    var key: String? = nil          // élément suivi pour la révision
    var speakCheck = false          // l'élève doit lire à voix haute
    var expected = ""
    var isOrder: Bool { !correct.isEmpty }
}

struct Lesson: Identifiable {
    let id: String
    let unit: String
    let title: String
    let symbol: String
    let xp: Int
    let make: () -> [Question]
}

struct Unit: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let lessons: [Lesson]
}

struct Letter { let ch, name, ar, tip: String }

enum Curriculum {
    static let letters: [Letter] = [
        Letter(ch: "ا", name: "Alif", ar: "ألف", tip: "voyelle longue « a » (porte le hamza)"),
        Letter(ch: "ب", name: "Baa", ar: "باء", tip: "comme le B de « bateau »"),
        Letter(ch: "ت", name: "Taa", ar: "تاء", tip: "comme le T de « table »"),
        Letter(ch: "ث", name: "Thaa", ar: "ثاء", tip: "comme le « th » anglais de « think »"),
        Letter(ch: "ج", name: "Jiim", ar: "جيم", tip: "comme le J de « jour »"),
        Letter(ch: "ح", name: "Ha profond", ar: "حاء", tip: "H soufflé et appuyé, du fond de la gorge"),
        Letter(ch: "خ", name: "Khaa", ar: "خاء", tip: "comme la jota espagnole ou le CH allemand"),
        Letter(ch: "د", name: "Daal", ar: "دال", tip: "comme le D de « date »"),
        Letter(ch: "ذ", name: "Dhaal", ar: "ذال", tip: "comme le « th » anglais de « this »"),
        Letter(ch: "ر", name: "Raa", ar: "راء", tip: "R roulé, comme en espagnol"),
        Letter(ch: "ز", name: "Zaay", ar: "زاي", tip: "comme le Z de « zèbre »"),
        Letter(ch: "س", name: "Siin", ar: "سين", tip: "comme le S de « sable »"),
        Letter(ch: "ش", name: "Shiin", ar: "شين", tip: "comme le CH de « chat »"),
        Letter(ch: "ص", name: "Saad", ar: "صاد", tip: "S emphatique, plus profond"),
        Letter(ch: "ض", name: "Daad", ar: "ضاد", tip: "D emphatique, plus profond"),
        Letter(ch: "ط", name: "Taa emphatique", ar: "طاء", tip: "T emphatique, plus profond"),
        Letter(ch: "ظ", name: "Zhaa", ar: "ظاء", tip: "« th » emphatique de « this »"),
        Letter(ch: "ع", name: "Ayn", ar: "عين", tip: "son guttural propre à l'arabe, gorge serrée"),
        Letter(ch: "غ", name: "Ghayn", ar: "غين", tip: "R grasseyé, comme le R français"),
        Letter(ch: "ف", name: "Faa", ar: "فاء", tip: "comme le F de « fleur »"),
        Letter(ch: "ق", name: "Qaaf", ar: "قاف", tip: "K profond, tout au fond de la gorge"),
        Letter(ch: "ك", name: "Kaaf", ar: "كاف", tip: "comme le K de « kilo »"),
        Letter(ch: "ل", name: "Laam", ar: "لام", tip: "comme le L de « lune »"),
        Letter(ch: "م", name: "Miim", ar: "ميم", tip: "comme le M de « maison »"),
        Letter(ch: "ن", name: "Nuun", ar: "نون", tip: "comme le N de « nuit »"),
        Letter(ch: "ه", name: "Ha léger", ar: "هاء", tip: "H aspiré, comme dans « hop »"),
        Letter(ch: "و", name: "Waaw", ar: "واو", tip: "comme le OU de « oui » (ou la voyelle « ou »)"),
        Letter(ch: "ي", name: "Yaa", ar: "ياء", tip: "comme le Y de « yaourt » (ou la voyelle « i »)"),
    ]

    static let words: [(ar: String, fr: String)] = [
        ("اللَّه", "Allah"), ("رَبّ", "Seigneur"), ("رَحْمَة", "miséricorde"), ("كِتَاب", "livre"),
        ("يَوْم", "jour"), ("نَاس", "gens"), ("مَاء", "eau"), ("أَرْض", "terre"), ("سَمَاء", "ciel"),
        ("نُور", "lumière"), ("قَلْب", "cœur"), ("صَلَاة", "prière"), ("زَكَاة", "aumône"),
        ("جَنَّة", "paradis"), ("نَار", "feu"), ("عِلْم", "savoir"), ("صَبْر", "patience"),
        ("حَقّ", "vérité"), ("خَيْر", "bien"), ("شَرّ", "mal"), ("رَسُول", "messager"),
        ("نَبِيّ", "prophète"), ("إِنْسَان", "être humain"), ("شَمْس", "soleil"), ("قَمَر", "lune"),
        ("لَيْل", "nuit"), ("نَهَار", "journée"), ("حَيَاة", "vie"), ("مَوْت", "mort"),
        ("سَلَام", "paix"), ("حَمْد", "louange"), ("عَبْد", "serviteur"), ("أَمْر", "ordre"),
        ("نَفْس", "âme"), ("بَيْت", "maison"), ("عَيْن", "œil"), ("يَد", "main"),
        ("أَب", "père"), ("أُمّ", "mère"), ("طَرِيق", "chemin"),
    ]

    static let letterGroups: [[Letter]] = [Array(letters[0..<5]), Array(letters[5..<10]), Array(letters[10..<15]),
                                           Array(letters[15..<20]), Array(letters[20..<24]), Array(letters[24..<28])]
    static let wordGroupCount = 4
    static func wordGroup(_ i: Int) -> [(ar: String, fr: String)] { Array(words[(i * 10)..<(i * 10 + 10)]) }

    static func readQuestions(_ group: [(ar: String, fr: String)]) -> [Question] {
        group.map { w in
            Question(prompt: "Lis ce mot à voix haute", big: w.ar, speak: w.ar, hint: w.fr,
                     explain: "\(w.ar) = \(w.fr)", key: "W:\(w.ar)", speakCheck: true, expected: w.ar)
        }
    }

    // MARK: Génération

    static func letterQuestions(_ group: [Letter], limit: Int = 11) -> [Question] {
        var qs: [Question] = []
        for l in group {
            let others = letters.filter { $0.ch != l.ch }.shuffled()
            let nameOpts = ([l.name] + others.prefix(3).map(\.name)).shuffled()
            qs.append(Question(prompt: "Comment s'appelle cette lettre ?", big: l.ch, speak: l.ar,
                               options: nameOpts, answer: nameOpts.firstIndex(of: l.name)!,
                               explain: "\(l.ch) = \(l.name) : \(l.tip).", key: "L:\(l.ch)"))
            let chOpts = ([l.ch] + others.prefix(3).map(\.ch)).shuffled()
            qs.append(Question(prompt: "Quelle lettre s'appelle « \(l.name) » ?",
                               options: chOpts, answer: chOpts.firstIndex(of: l.ch)!, optionsArabic: true,
                               explain: "\(l.ch) = \(l.name) : \(l.tip).", key: "L:\(l.ch)"))
            let chOpts2 = ([l.ch] + others.suffix(3).map(\.ch)).shuffled()
            qs.append(Question(prompt: "Écoute et choisis la lettre", speak: l.ar,
                               options: chOpts2, answer: chOpts2.firstIndex(of: l.ch)!, optionsArabic: true,
                               explain: "\(l.ch) = \(l.name) : \(l.tip).", key: "L:\(l.ch)"))
        }
        return Array(qs.shuffled().prefix(limit))
    }

    static func wordQuestions(_ group: [(ar: String, fr: String)], limit: Int = 11) -> [Question] {
        var qs: [Question] = []
        for w in group {
            let others = words.filter { $0.ar != w.ar }.shuffled()
            let frOpts = ([w.fr] + others.prefix(3).map(\.fr)).shuffled()
            qs.append(Question(prompt: "Que veut dire ce mot ?", big: w.ar, speak: w.ar,
                               options: frOpts, answer: frOpts.firstIndex(of: w.fr)!,
                               explain: "\(w.ar) = \(w.fr)", key: "W:\(w.ar)"))
            let arOpts = ([w.ar] + others.prefix(3).map(\.ar)).shuffled()
            qs.append(Question(prompt: "Comment dit-on « \(w.fr) » ?",
                               options: arOpts, answer: arOpts.firstIndex(of: w.ar)!, optionsArabic: true,
                               explain: "\(w.fr) = \(w.ar)", key: "W:\(w.ar)"))
            let arOpts2 = ([w.ar] + others.suffix(3).map(\.ar)).shuffled()
            qs.append(Question(prompt: "Écoute et choisis le mot", speak: w.ar,
                               options: arOpts2, answer: arOpts2.firstIndex(of: w.ar)!, optionsArabic: true,
                               explain: "\(w.ar) = \(w.fr)", key: "W:\(w.ar)"))
        }
        return Array(qs.shuffled().prefix(limit))
    }

    static func vowelQuestions() -> [Question] {
        func q(_ prompt: String, big: String? = nil, _ options: [String], _ answer: Int, arabic: Bool, _ explain: String) -> Question {
            let correct = options[answer]
            let sh = options.shuffled()
            return Question(prompt: prompt, big: big, options: sh, answer: sh.firstIndex(of: correct)!,
                            optionsArabic: arabic, explain: explain)
        }
        return [
            q("Quel signe donne le son « a » ?", ["بَ", "بِ", "بُ", "بْ"], 0, arabic: true,
              "La fatha (petit trait au-dessus) donne « a » : بَ = ba."),
            q("Quel signe donne le son « i » ?", ["بِ", "بَ", "بُ", "بْ"], 0, arabic: true,
              "La kasra (petit trait en dessous) donne « i » : بِ = bi."),
            q("Quel signe donne le son « ou » ?", ["بُ", "بِ", "بَ", "بْ"], 0, arabic: true,
              "La damma (petit « و » au-dessus) donne « ou » : بُ = bou."),
            q("Quel signe indique l'absence de voyelle ?", ["بْ", "بَ", "بِ", "بُ"], 0, arabic: true,
              "Le soukoun (petit rond) : la lettre se prononce sans voyelle. بْ = b."),
            q("Quel signe double la consonne ?", ["بّ", "بْ", "بَ", "بِ"], 0, arabic: true,
              "La shadda double la lettre : رَبِّ = rabbi."),
            q("Comment lit-on ce mot ?", big: "قُلْ", ["qoul", "qal", "qil", "qala"], 0, arabic: false,
              "قُ = qou, لْ = l : « qoul » (dis !)."),
            q("Comment lit-on ce mot ?", big: "رَبِّ", ["rabbi", "rabou", "rabi", "rib"], 0, arabic: false,
              "رَ = ra, بِّ = bbi (shadda) : « rabbi » (mon Seigneur)."),
            q("Comment lit-on ce mot ?", big: "كِتَاب", ["kitâb", "katab", "koutoub", "kitib"], 0, arabic: false,
              "كِ = ki, تَا = tâ (alif long), ب = b : « kitâb » (livre)."),
        ].shuffled()
    }

    static func orderQuestions(surah n: Int) -> [Question] {
        guard let s = Quran.surah(n) else { return [] }
        var qs: [Question] = []
        for a in s.ayahs {
            let w = a.ar.split(separator: " ").map(String.init)
            guard w.count >= 2, w.count <= 14 else { continue }
            var t = w.shuffled()
            if t == w, w.count > 2 { t = w.reversed() }
            qs.append(Question(prompt: "Remets le verset dans l'ordre", big: nil, speak: a.ar, tiles: t,
                               correct: w, hint: a.fr, explain: "\(s.en) \(s.n):\(a.n) — \(a.fr)"))
        }
        return Array(qs.prefix(8))
    }

    // MARK: Plan de cours

    static let units: [Unit] = {
        var alpha: [Lesson] = []
        let groups = [Array(letters[0..<5]), Array(letters[5..<10]), Array(letters[10..<15]),
                      Array(letters[15..<20]), Array(letters[20..<24]), Array(letters[24..<28])]
        let syms = ["a.circle.fill", "b.circle.fill", "c.circle.fill", "d.circle.fill", "e.circle.fill", "f.circle.fill"]
        for (i, g) in groups.enumerated() {
            alpha.append(Lesson(id: "alpha\(i + 1)", unit: "alpha", title: g.map(\.ch).joined(separator: " "),
                                symbol: syms[i], xp: 15) { letterQuestions(g) })
        }
        let vowels = [Lesson(id: "vowels1", unit: "vowels", title: "Voyelles", symbol: "textformat.abc", xp: 15) { vowelQuestions() }]
        var vocab: [Lesson] = []
        for i in 0..<4 {
            let g = Array(words[(i * 10)..<(i * 10 + 10)])
            vocab.append(Lesson(id: "vocab\(i + 1)", unit: "vocab", title: "Mots \(i + 1)", symbol: "text.book.closed.fill", xp: 20) { wordQuestions(g) })
        }
        var read: [Lesson] = []
        for i in 0..<5 {
            let g = Array(words[(i * 8)..<(i * 8 + 8)])
            read.append(Lesson(id: "read\(i + 1)", unit: "read", title: "Lecture \(i + 1)", symbol: "mic.fill", xp: 20) { readQuestions(g) })
        }
        let recite: [(Int, String)] = [(1, "Al-Fatiha"), (112, "Al-Ikhlas"), (108, "Al-Kawthar"), (103, "Al-Asr"), (114, "An-Nas"), (113, "Al-Falaq")]
        let rec = recite.map { n, name in
            Lesson(id: "recite\(n)", unit: "recite", title: name, symbol: "waveform", xp: 25) { orderQuestions(surah: n) }
        }
        return [
            Unit(id: "alpha", title: "Unité 1 · L'alphabet", subtitle: "Les 28 lettres, leur nom et leur son", lessons: alpha),
            Unit(id: "vowels", title: "Unité 2 · Les voyelles", subtitle: "Lire les mots avec leurs signes", lessons: vowels),
            Unit(id: "vocab", title: "Unité 3 · Mots du Coran", subtitle: "40 mots qu'on retrouve partout", lessons: vocab),
            Unit(id: "read", title: "Unité 4 · Lire à voix haute", subtitle: "Dis les mots, je vérifie ta lecture au micro", lessons: read),
            Unit(id: "recite", title: "Unité 5 · Réciter", subtitle: "Remets les versets dans l'ordre", lessons: rec),
        ]
    }()

    static var all: [Lesson] { units.flatMap(\.lessons) }
}
