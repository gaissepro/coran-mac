import SwiftUI
import Speech
import AVFoundation
import Observation

// MARK: - Comparaison texte attendu / texte entendu

enum Compare {
    /// Normalise l'arabe : sans voyelles, variantes d'alif et de ya/ha unifiées.
    static func norm(_ s: String) -> String {
        let cleaned = String(String.UnicodeScalarView(s.unicodeScalars.filter { u in
            let v = u.value
            return !((0x06D6...0x06ED).contains(v) || (0x0610...0x061A).contains(v) || (0x064B...0x065F).contains(v) || v == 0x0670 || v == 0x0640)
        }))
        var t = fold(cleaned)
        for (a, b) in [("أ", "ا"), ("إ", "ا"), ("آ", "ا"), ("ٱ", "ا"), ("ى", "ي"), ("ة", "ه"), ("ؤ", "و"), ("ئ", "ي")] {
            t = t.replacingOccurrences(of: a, with: b)
        }
        return t
    }

    static func words(_ s: String) -> [String] {
        s.split(whereSeparator: { $0 == " " || $0 == "\n" }).map { norm(String($0)) }.filter { !$0.isEmpty }
    }

    static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(a), y = Array(b)
        if x.isEmpty || y.isEmpty { return 0 }
        var prev = Array(0...y.count)
        for i in 1...x.count {
            var cur = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return 1 - Double(prev[y.count]) / Double(max(x.count, y.count))
    }

    /// Pour chaque mot attendu : a-t-il été entendu, dans l'ordre ?
    static func match(expected: String, heard: String) -> (flags: [Bool], ratio: Double) {
        let exp = expected.split(separator: " ").map(String.init)
        let heardW = words(heard)
        var j = 0
        var flags: [Bool] = []
        for e in exp {
            let ne = norm(e)
            var found = false
            var k = j
            while k < heardW.count && k < j + 4 {
                if similarity(ne, heardW[k]) >= 0.66 { found = true; j = k + 1; break }
                k += 1
            }
            flags.append(found)
        }
        let ok = flags.filter { $0 }.count
        return (flags, exp.isEmpty ? 0 : Double(ok) / Double(exp.count))
    }
}

// MARK: - Écoute (micro + reconnaissance vocale)

@Observable
final class Listener {
    enum State { case idle, asking, listening, finishing, denied, unavailable }
    var state: State = .idle
    var transcript = ""
    var level: Float = 0

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var completion: ((String) -> Void)?
    private var finished = false

    func start() {
        guard let recognizer, recognizer.isAvailable else { state = .unavailable; return }
        state = .asking
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { self.state = .denied; return }
                AVCaptureDevice.requestAccess(for: .audio) { ok in
                    DispatchQueue.main.async { if ok { self.begin() } else { self.state = .denied } }
                }
            }
        }
    }

    private func begin() {
        guard let recognizer else { state = .unavailable; return }
        transcript = ""
        finished = false
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req
        let input = engine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        guard fmt.sampleRate > 0 else { state = .unavailable; return }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
            if let ch = buf.floatChannelData?[0] {
                var sum: Float = 0
                let n = Int(buf.frameLength)
                for i in stride(from: 0, to: n, by: 8) { sum += ch[i] * ch[i] }
                let rms = sqrt(sum / Float(max(1, n / 8)))
                DispatchQueue.main.async { self?.level = min(1, rms * 8) }
            }
        }
        engine.prepare()
        do { try engine.start() } catch { state = .unavailable; return }
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let r = result { self.transcript = r.bestTranscription.formattedString }
                if (result?.isFinal ?? false) || error != nil { self.complete() }
            }
        }
        state = .listening
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            if self?.state == .listening { self?.stop { _ in } }
        }
    }

    /// Termine l'écoute et renvoie le texte entendu.
    func stop(_ done: @escaping (String) -> Void) {
        guard state == .listening else { return }
        completion = done
        state = .finishing
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        level = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in self?.complete() }
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        task?.cancel(); task = nil; request = nil
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        state = .idle
        let cb = completion; completion = nil
        cb?(transcript)
    }

    func cancel() {
        finished = true
        task?.cancel(); task = nil; request = nil
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        state = .idle; level = 0; completion = nil
    }
}

// MARK: - Bouton micro réutilisable

struct MicCard: View {
    let st: AppState
    let expected: String
    let onResult: (_ ratio: Double, _ flags: [Bool], _ heard: String) -> Void
    @State private var L = Listener()

    var message: String {
        switch L.state {
        case .idle: return "Appuie, puis lis à voix haute"
        case .asking: return "Autorisation du micro…"
        case .listening: return "Je t'écoute… appuie pour terminer"
        case .finishing: return "Analyse…"
        case .denied: return "Micro ou reconnaissance vocale refusés (Réglages Système > Confidentialité)"
        case .unavailable: return "Reconnaissance vocale indisponible sur ce Mac"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                if L.state == .listening {
                    L.stop { heard in
                        let m = Compare.match(expected: expected, heard: heard)
                        onResult(m.ratio, m.flags, heard)
                    }
                } else if L.state == .idle || L.state == .denied || L.state == .unavailable {
                    Audio.shared.play(.tap)
                    L.start()
                }
            } label: {
                ZStack {
                    Circle().fill(L.state == .listening ? Palette.bad : st.accentColor).frame(width: 78, height: 78)
                    if L.state == .listening {
                        Circle().stroke(Palette.bad.opacity(0.5), lineWidth: 3)
                            .frame(width: 78 + CGFloat(L.level) * 46, height: 78 + CGFloat(L.level) * 46)
                            .animation(.easeOut(duration: 0.1), value: L.level)
                    }
                    Image(systemName: L.state == .listening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(st.pal.scheme == .dark ? Color.black : Color.white)
                }
                .frame(width: 130, height: 130)
            }
            .buttonStyle(.plain)
            Text(message).font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted).multilineTextAlignment(.center)
            if L.state == .listening, !L.transcript.isEmpty {
                Text(L.transcript).font(.custom("Amiri Quran", size: 24)).foregroundStyle(st.pal.muted)
                    .environment(\.layoutDirection, .rightToLeft).lineLimit(2)
            }
        }
        .onDisappear { L.cancel() }
    }
}

// MARK: - Panneau « Je récite » sur un verset

struct RecitePanel: View {
    @Bindable var st: AppState
    let ref: Ref
    @State private var flags: [Bool]? = nil
    @State private var ratio = 0.0
    @State private var heard = ""
    @State private var attempt = 0

    var verse: Ayah? { Quran.surah(ref.surah)?.ayahs.first { $0.n == ref.ayah } }

    var body: some View {
        ZStack {
            Color.black.opacity(st.theme == .dark ? 0.6 : 0.3).ignoresSafeArea().onTapGesture { st.checkRef = nil }
            VStack(spacing: 18) {
                HStack {
                    Text("Je récite · \(Quran.surah(ref.surah)?.en ?? "") \(ref.surah):\(ref.ayah)")
                        .font(.custom("Inter", size: 13).weight(.semibold)).foregroundStyle(st.pal.muted)
                    Spacer()
                    Button { Audio.shared.play(.tap); st.checkRef = nil } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(st.pal.muted)
                    }.buttonStyle(.plain)
                }
                if let v = verse {
                    let words = v.ar.split(separator: " ").map(String.init)
                    Flow(spacing: 8, rtl: true) {
                        ForEach(Array(words.enumerated()), id: \.offset) { i, w in
                            let state: Bool? = flags.flatMap { i < $0.count ? $0[i] : nil }
                            Text(w).font(.custom("Amiri Quran", size: st.arSize * 0.95))
                                .foregroundStyle(state == nil ? st.pal.fg : (state! ? Palette.good : Palette.bad))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    if let f = flags {
                        VStack(spacing: 6) {
                            Text("\(Int(ratio * 100)) % des mots reconnus")
                                .font(.custom("Inter", size: 17).weight(.bold))
                                .foregroundStyle(ratio >= 0.8 ? Palette.good : (ratio >= 0.5 ? st.accentColor : Palette.bad))
                            Text(f.contains(false) ? "En rouge : mots non reconnus. Écoute le récitant et réessaie." : "Tous les mots ont été reconnus, mashallah !")
                                .font(.custom("Inter", size: 13)).foregroundStyle(st.pal.muted)
                            if !heard.isEmpty {
                                Text("J'ai entendu : \(heard)").font(.custom("Amiri Quran", size: 20)).foregroundStyle(st.pal.muted)
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                        }
                    }
                    MicCard(st: st, expected: v.ar) { r, f, h in
                        ratio = r; flags = f; heard = h; attempt += 1
                        Audio.shared.play(r >= 0.8 ? .ok : .soft)
                        if r >= 0.8 { st.rewardRecitation(ref) }
                    }
                    .id(attempt)

                    HStack(spacing: 14) {
                        Button { st.reciter.start(ref.surah, from: ref.ayah) } label: {
                            Label("Écouter le récitant", systemImage: "play.circle.fill")
                        }
                        Text("·").foregroundStyle(st.pal.muted)
                        Text("Reconnaissance vocale d'Apple : elle vérifie les mots, pas le tajwid.")
                            .foregroundStyle(st.pal.muted)
                    }
                    .font(.custom("Inter", size: 12).weight(.medium)).foregroundStyle(st.accentColor).buttonStyle(.plain)
                }
            }
            .padding(26)
            .frame(width: 640)
            .background(st.pal.bg, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(st.pal.line.opacity(2)))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 16)
        }
        .onExitCommand { st.checkRef = nil }
    }
}
