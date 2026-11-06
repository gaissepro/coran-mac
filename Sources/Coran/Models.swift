import Foundation

struct Ayah: Codable, Identifiable, Hashable {
    let n: Int      // numéro dans la sourate
    let ar: String
    let fr: String
    let j: Int      // juz
    let p: Int      // page
    var id: Int { n }
}

struct Surah: Codable, Identifiable, Hashable {
    let n: Int
    let ar: String
    let en: String
    let tr: String
    let type: String
    let ayahs: [Ayah]
    var id: Int { n }
    var lieu: String { type == "Meccan" ? "Mecquoise" : "Médinoise" }
}

struct Ref: Hashable, Codable {
    let surah: Int
    let ayah: Int
    var key: String { "\(surah):\(ayah)" }
}

struct Hadith: Codable, Identifiable, Hashable {
    let n: Int
    let ar: String
    let fr: String
    var id: Int { n }
}

struct HadithBook: Codable, Identifiable, Hashable {
    let id: String
    let fr: String
    let ar: String
    let items: [Hadith]
    var short: String { id == "nawawi" ? "40 Nawawi" : id == "qudsi" ? "40 Qudsi" : fr }
}

enum Hadiths {
    static let books: [HadithBook] = {
        let override = ProcessInfo.processInfo.environment["CORAN_HADITH"].map { URL(fileURLWithPath: $0) }
        guard let url = override ?? Bundle.main.url(forResource: "hadith", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let b = try? JSONDecoder().decode([HadithBook].self, from: data) else { return [] }
        return b
    }()
    static func book(_ id: String) -> HadithBook? { books.first { $0.id == id } }
}

enum Quran {
    static let surahs: [Surah] = {
        let override = ProcessInfo.processInfo.environment["CORAN_DATA"].map { URL(fileURLWithPath: $0) }
        guard let url = override ?? Bundle.main.url(forResource: "quran", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode([Surah].self, from: data) else { return [] }
        return s
    }()

    static func surah(_ n: Int) -> Surah? {
        surahs.indices.contains(n - 1) ? surahs[n - 1] : nil
    }
}

func arabicDigits(_ n: Int) -> String {
    let d = Array("٠١٢٣٤٥٦٧٨٩")
    return String(String(n).compactMap { $0.wholeNumberValue.map { d[$0] } })
}

/// Retire accents et diacritiques pour comparer.
func fold(_ s: String) -> String {
    s.replacingOccurrences(of: "ٱ", with: "ا").replacingOccurrences(of: "ـ", with: "")
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "fr"))
        .unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) && $0.properties.generalCategory != .nonspacingMark }
        .map(String.init).joined()
}


// MARK: - Données complémentaires (noms français, contexte, notes, glossaire)

struct SurahMeta: Decodable { let fr: String; let place: String; let order: Int }
struct ExtraData: Decodable { let meta: [String: SurahMeta]; let notes: [String: String]; let montada: [String: String] }

enum Meta {
    private static func load<T: Decodable>(_ name: String, _ type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json")
                ?? ProcessInfo.processInfo.environment["CORAN_DATA"].map({ URL(fileURLWithPath: $0).deletingLastPathComponent().appendingPathComponent("\(name).json") }),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    static let extra: ExtraData? = load("extra", ExtraData.self)
    static let context: [String: String] = load("context", [String: String].self) ?? [:]

    static func frName(_ n: Int) -> String { extra?.meta[String(n)]?.fr ?? Quran.surah(n)?.tr ?? "" }
    static func place(_ n: Int) -> String {
        guard let p = extra?.meta[String(n)]?.place else { return Quran.surah(n)?.lieu ?? "" }
        return p == "makkah" ? "Mecquoise" : "Médinoise"
    }
    static func order(_ n: Int) -> Int? { extra?.meta[String(n)]?.order }
    static func context(_ n: Int) -> String? { context[String(n)] }
    static func montada(_ s: Int, _ a: Int) -> String? { extra?.montada["\(s):\(a)"] }

    /// Notes explicatives de la traduction Montada, découpées par numéro de note.
    static func notes(_ s: Int, _ a: Int) -> [String] {
        guard let raw = extra?.notes["\(s):\(a)"] else { return [] }
        let parts = raw.components(separatedBy: "[").compactMap { chunk -> String? in
            guard let close = chunk.firstIndex(of: "]") else { return nil }
            let body = chunk[chunk.index(after: close)...].trimmingCharacters(in: .whitespacesAndNewlines)
            return body.isEmpty ? nil : body
        }
        return parts.isEmpty ? [raw] : parts
    }
    static func hasNotes(_ s: Int, _ a: Int) -> Bool { extra?.notes["\(s):\(a)"] != nil }
}

struct GlossEntry: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let ar: String
    let forms: [String]
    let refs: [String]?
    let text: String
}

enum Glossary {
    static let entries: [GlossEntry] = {
        guard let url = Bundle.main.url(forResource: "glossary", withExtension: "json")
                ?? ProcessInfo.processInfo.environment["CORAN_DATA"].map({ URL(fileURLWithPath: $0).deletingLastPathComponent().appendingPathComponent("glossary.json") }),
              let data = try? Data(contentsOf: url),
              let e = try? JSONDecoder().decode([GlossEntry].self, from: data) else { return [] }
        return e
    }()

    private static let index: [String: [GlossEntry]] = {
        var d: [String: [GlossEntry]] = [:]
        for e in entries { for f in e.forms { d[Compare.norm(f), default: []].append(e) } }
        return d
    }()

    private static let prefixes = ["وال", "فال", "بال", "كال", "لل", "ال", "و", "ف", "ب", "ل", "ك"]

    static func match(_ word: String, ref: String) -> GlossEntry? {
        let w = Compare.norm(word)
        guard !w.isEmpty else { return nil }
        var cands = [w]
        for p in prefixes where w.hasPrefix(p) && w.count > p.count + 1 { cands.append(String(w.dropFirst(p.count))) }
        for c in cands {
            if let es = index[c], let e = es.first(where: { $0.refs?.contains(ref) == true }) { return e }
        }
        for c in cands {
            if let es = index[c], let e = es.first(where: { $0.refs == nil }) { return e }
        }
        return nil
    }

    private static var cache: [String: [GlossEntry?]] = [:]

    /// Une entrée (ou rien) par mot du verset, mise en cache.
    static func matches(ref: String, words: [String]) -> [GlossEntry?] {
        if let c = cache[ref] { return c }
        let m = words.map { match($0, ref: ref) }
        cache[ref] = m
        return m
    }

    static func forVerse(_ s: Int, _ a: Ayah) -> [GlossEntry] {
        let words = a.ar.split(separator: " ").map(String.init)
        var seen = Set<String>()
        return matches(ref: "\(s):\(a.n)", words: words).compactMap { $0 }.filter { seen.insert($0.id).inserted }
    }
}
