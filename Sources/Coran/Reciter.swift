import Foundation
import AVFoundation
import Observation

let reciters: [(id: String, name: String)] = [
    ("Alafasy_128kbps", "Mishary Alafasy"),
    ("Husary_128kbps", "Mahmoud Al-Husary"),
    ("Abdul_Basit_Murattal_192kbps", "Abdul Basit"),
    ("Minshawy_Murattal_128kbps", "Al-Minshawi"),
    ("Abdurrahmaan_As-Sudais_192kbps", "As-Sudais"),
]

/// Lecteur de récitation verset par verset (source : everyayah.com), avec cache disque.
@Observable
final class Reciter {
    var reciterId: String { didSet { UserDefaults.standard.set(reciterId, forKey: "reciter") } }
    var surah: Int? = nil
    var ayah = 0                // 0 = bismillah d'ouverture
    var playing = false
    var fraction = 0.0          // avancement dans le verset en cours
    var repeatVerse = false
    var speed = 1.0 { didSet { if playing { player.rate = Float(speed) } } }
    var onFinish: ((Int) -> Void)?

    private let player = AVPlayer()
    private var endObs: NSObjectProtocol?
    private let muted = ProcessInfo.processInfo.environment["CORAN_SNAPSHOT"] != nil

    init() {
        reciterId = UserDefaults.standard.string(forKey: "reciter") ?? reciters[0].id
        player.volume = muted ? 0 : 1
        attachClock()
    }

    var reciterName: String { reciters.first { $0.id == reciterId }?.name ?? "" }

    private func cacheDir() -> URL {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Coran/audio/\(reciterId)", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private func source(_ s: Int, _ a: Int, download: Bool = true) -> URL {
        let name = String(format: "%03d%03d.mp3", s, a)
        let local = cacheDir().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: local.path) { return local }
        let remote = URL(string: "https://everyayah.com/data/\(reciterId)/\(name)")!
        if download {
            URLSession.shared.downloadTask(with: remote) { tmp, resp, _ in
                guard let tmp, (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
                try? FileManager.default.removeItem(at: local)
                try? FileManager.default.moveItem(at: tmp, to: local)
            }.resume()
        }
        return remote
    }

    private func prefetch(_ s: Int, _ a: Int) {
        guard let count = Quran.surah(s)?.ayahs.count, a >= 1, a <= count else { return }
        let name = String(format: "%03d%03d.mp3", s, a)
        let local = cacheDir().appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: local.path) else { return }
        _ = source(s, a)
    }

    /// Lance la sourate. `from` = 1 pour partir du début (avec la basmala si la sourate en a une).
    func start(_ s: Int, from a: Int = 1) {
        surah = s
        load(a == 1 && s != 1 && s != 9 ? 0 : a)
    }

    private func load(_ a: Int) {
        guard let s = surah else { return }
        ayah = a
        fraction = 0
        let item = AVPlayerItem(url: a == 0 ? source(1, 1) : source(s, a))
        if let e = endObs { NotificationCenter.default.removeObserver(e) }
        endObs = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.ended()
        }
        player.replaceCurrentItem(with: item)
        player.playImmediately(atRate: Float(speed))
        playing = true
        prefetch(s, a + 1)
    }

    private func ended() {
        guard let s = surah else { return }
        if repeatVerse { load(ayah); return }
        let count = Quran.surah(s)?.ayahs.count ?? 0
        if ayah < count { load(ayah + 1) }
        else { playing = false; fraction = 1; onFinish?(s) }
    }

    func toggle() {
        guard surah != nil else { return }
        if playing { player.pause(); playing = false } else { player.playImmediately(atRate: Float(speed)); playing = true }
    }

    func next() {
        guard let s = surah, ayah < (Quran.surah(s)?.ayahs.count ?? 0) else { return }
        load(ayah + 1)
    }

    func previous() {
        guard let s = surah else { return }
        let minA = (s != 1 && s != 9) ? 0 : 1
        load(max(minA, ayah - 1))
    }

    func stop() {
        player.pause()
        playing = false
        surah = nil
        ayah = 0
        fraction = 0
    }

    func tick(_ t: CMTime) {
        guard let item = player.currentItem else { return }
        let d = item.duration.seconds
        if d.isFinite, d > 0 { fraction = min(1, max(0, t.seconds / d)) }
    }
}

extension Reciter {
    /// À appeler une fois après init : branche l'observateur de temps.
    func attachClock() {
        _ = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.08, preferredTimescale: 600), queue: .main) { [weak self] t in
            self?.tick(t)
        }
    }
}
