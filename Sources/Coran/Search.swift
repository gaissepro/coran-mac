import Foundation

struct Hit: Identifiable {
    enum Kind { case surah(Int), ayah(Ref), hadith(String, Int) }
    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let arabic: String
}

enum Search {
    /// Translittération grossière pour que « bakara » trouve « Al-Baqara ».
    static func translit(_ s: String) -> String {
        var t = fold(s)
        for (a, b) in [("kh", "k"), ("gh", "g"), ("q", "k"), ("aa", "a"), ("ee", "i"), ("ii", "i"), ("oo", "u"),
                       ("ou", "u"), ("uu", "u"), ("ss", "s"), ("tt", "t"), ("dd", "d"), ("ll", "l"), ("mm", "m"),
                       ("nn", "n"), ("rr", "r"), ("bb", "b"), ("hh", "h"), ("w", "u"), ("y", "i")] {
            t = t.replacingOccurrences(of: a, with: b)
        }
        return t
    }

    static let surahKeys: [(Int, String, String)] = Quran.surahs.map { s in
        (s.n, translit(s.en), fold(s.ar))
    }

    static let frIndex: [(Ref, String)] = Quran.surahs.flatMap { s in
        s.ayahs.map { (Ref(surah: s.n, ayah: $0.n), fold($0.fr)) }
    }

    static let hadithIndex: [(String, Int, String)] = Hadiths.books.flatMap { b in
        b.items.map { (b.id, $0.n, fold($0.fr)) }
    }

    static func run(_ raw: String, favorites: Set<String>) -> [Hit] {
        let q = raw.trimmingCharacters(in: .whitespaces)
        var hits: [Hit] = []

        if q.isEmpty {
            for key in favorites.sorted() where key.hasPrefix("h:") {
                let p = key.split(separator: ":").map(String.init)
                if p.count == 3, let n = Int(p[2]), let b = Hadiths.book(p[1]), let h = b.items.first(where: { $0.n == n }) {
                    hits.append(Hit(kind: .hadith(p[1], n), title: "★ \(b.fr) · \(n)", subtitle: h.fr, arabic: ""))
                }
            }
            for key in favorites.sorted() where !key.hasPrefix("h:") {
                let p = key.split(separator: ":").compactMap { Int($0) }
                if p.count == 2, let h = ayahHit(Ref(surah: p[0], ayah: p[1]), prefix: "★ ") { hits.append(h) }
            }
            return Array(hits.prefix(12))
        }

        // « 2:255 », « 2 255 », « 36.1 »
        let parts = q.split(whereSeparator: { ": .,-".contains($0) }).compactMap { Int($0) }
        if parts.count == 2, let s = Quran.surah(parts[0]), s.ayahs.indices.contains(parts[1] - 1) {
            if let h = ayahHit(Ref(surah: parts[0], ayah: parts[1]), prefix: "") { hits.append(h) }
        }
        if parts.count == 1, let s = Quran.surah(parts[0]), q.allSatisfy(\.isNumber) {
            hits.append(surahHit(s))
        }

        let compact = fold(q)
        if ["ayatalkursi", "ayatulkursi", "ayatelkursi", "kursi", "versetdutrone", "versetdutrône"].contains(compact),
           let h = ayahHit(Ref(surah: 2, ayah: 255), prefix: "Ayat al-Kursi · ") { hits.append(h) }

        let tq = translit(q)
        let aq = fold(q)
        if tq.count >= 2 {
            for (n, k, a) in surahKeys where k.contains(tq) || a.contains(aq) {
                if let s = Quran.surah(n), !hits.contains(where: { if case .surah(let x) = $0.kind { return x == n } else { return false } }) {
                    hits.append(surahHit(s))
                }
            }
        }

        let fq = fold(q)
        if fq.count >= 3 {
            var count = 0
            for (r, text) in frIndex where text.contains(fq) {
                if let h = ayahHit(r, prefix: "") { hits.append(h) }
                count += 1
                if count >= 25 { break }
            }
        }
        if fq.count >= 3 {
            var c = 0
            for (b, n, text) in hadithIndex where text.contains(fq) {
                if let book = Hadiths.book(b), let h = book.items.first(where: { $0.n == n }) {
                    hits.append(Hit(kind: .hadith(b, n), title: "\(book.fr) · hadith \(n)", subtitle: h.fr, arabic: ""))
                }
                c += 1
                if c >= 10 { break }
            }
        }
        return hits
    }

    static func surahHit(_ s: Surah) -> Hit {
        Hit(kind: .surah(s.n), title: "\(s.n). \(s.en)", subtitle: "\(s.ayahs.count) versets · \(s.lieu)", arabic: s.ar)
    }

    static func ayahHit(_ r: Ref, prefix: String) -> Hit? {
        guard let s = Quran.surah(r.surah), s.ayahs.indices.contains(r.ayah - 1) else { return nil }
        let a = s.ayahs[r.ayah - 1]
        return Hit(kind: .ayah(r), title: "\(prefix)\(s.en) \(r.surah):\(r.ayah)", subtitle: a.fr, arabic: "")
    }
}
