import AppKit
import CoreText

let fontsDir = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]
let iconPath = CommandLine.arguments[3]
for f in ["AmiriQuran-Regular.ttf", "Inter.ttf", "Literata.ttf"] {
    CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: "\(fontsDir)/\(f)") as CFURL, .process, nil)
}
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let W: CGFloat = 1920, H: CGFloat = 1080
func col(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}
func font(_ family: String, _ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
    let d = NSFontDescriptor(fontAttributes: [.family: family, .traits: [NSFontDescriptor.TraitKey.weight: weight]])
    return NSFont(descriptor: d, size: size) ?? NSFont(name: family, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func canvas(_ w: CGFloat, _ h: CGFloat, draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h), bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = g
    draw(g.cgContext)
    NSGraphicsContext.current = nil
    return rep
}
func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
}

/// Texte centré horizontalement, `top` = distance depuis le haut de l'image.
@discardableResult
func text(_ s: String, size: CGFloat, family: String = "Inter", weight: NSFont.Weight = .regular, color: NSColor, centerX: CGFloat = W / 2,
          top: CGFloat, rtl: Bool = false, tracking: CGFloat = 0, canvasH: CGFloat = H) -> NSSize {
    let p = NSMutableParagraphStyle(); p.alignment = .center
    if rtl { p.baseWritingDirection = .rightToLeft }
    let attrs: [NSAttributedString.Key: Any] = [.font: font(family, size, weight), .foregroundColor: color, .paragraphStyle: p, .kern: tracking]
    let a = NSAttributedString(string: s, attributes: attrs)
    let sz = a.size()
    a.draw(in: NSRect(x: centerX - sz.width / 2 - 2, y: canvasH - top - sz.height, width: sz.width + 4, height: sz.height))
    return sz
}

func background(_ ctx: CGContext) {
    col(0x0A0A0B).setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    let g1 = NSGradient(colors: [col(0x8FD9B6, 0.20), col(0x8FD9B6, 0)], atLocations: [0, 1], colorSpace: .sRGB)!
    g1.draw(fromCenter: NSPoint(x: W * 0.5, y: H * 0.42), radius: 0, toCenter: NSPoint(x: W * 0.5, y: H * 0.42), radius: 820, options: [])
    let g2 = NSGradient(colors: [col(0xF6B47B, 0.10), col(0xF6B47B, 0)], atLocations: [0, 1], colorSpace: .sRGB)!
    g2.draw(fromCenter: NSPoint(x: W * 0.88, y: H * 0.9), radius: 0, toCenter: NSPoint(x: W * 0.88, y: H * 0.9), radius: 560, options: [])
    let g3 = NSGradient(colors: [col(0xB7A7F0, 0.08), col(0xB7A7F0, 0)], atLocations: [0, 1], colorSpace: .sRGB)!
    g3.draw(fromCenter: NSPoint(x: W * 0.08, y: H * 0.15), radius: 0, toCenter: NSPoint(x: W * 0.08, y: H * 0.15), radius: 520, options: [])
}

// Fond seul
save(canvas(W, H) { c in background(c) }, "bg.png")

// Fenêtre : position et taille de l'app dans l'image
let winX: CGFloat = 310, winY: CGFloat = 165, winW: CGFloat = 1300, winH: CGFloat = 880, radius: CGFloat = 22

// Masque arrondi (blanc sur noir) pour la fenêtre
save(canvas(winW, winH) { c in
    col(0x000000).setFill(); NSRect(x: 0, y: 0, width: winW, height: winH).fill()
    col(0xFFFFFF).setFill(); NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: winW, height: winH), xRadius: radius, yRadius: radius).fill()
}, "mask.png")

// Ombre portée sous la fenêtre
save(canvas(W, H) { c in
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -26), blur: 90, color: NSColor.black.withAlphaComponent(0.85).cgColor)
    col(0x000000).setFill()
    NSBezierPath(roundedRect: NSRect(x: winX, y: H - winY - winH, width: winW, height: winH), xRadius: radius, yRadius: radius).fill()
    c.restoreGState()
    // fin liseré clair autour de la fenêtre
    col(0xFFFFFF, 0.12).setStroke()
    let r = NSBezierPath(roundedRect: NSRect(x: winX - 0.5, y: H - winY - winH - 0.5, width: winW + 1, height: winH + 1), xRadius: radius, yRadius: radius)
    r.lineWidth = 1.5; r.stroke()
}, "shadow.png")

// Légendes : pastille en haut au centre
let captions = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "\(outDir)/captions.json"))) as! [String]
for (i, cap) in captions.enumerated() {
    save(canvas(W, H) { c in
        let attrs: [NSAttributedString.Key: Any] = [.font: font("Inter", 38, .semibold)]
        let tw = NSAttributedString(string: cap, attributes: attrs).size().width
        let pw = tw + 110, ph: CGFloat = 78
        let px = (W - pw) / 2, py = H - 36 - ph
        let pill = NSBezierPath(roundedRect: NSRect(x: px, y: py, width: pw, height: ph), xRadius: ph / 2, yRadius: ph / 2)
        c.saveGState()
        c.setShadow(offset: CGSize(width: 0, height: -8), blur: 30, color: NSColor.black.withAlphaComponent(0.5).cgColor)
        col(0x161618, 0.92).setFill(); pill.fill()
        c.restoreGState()
        col(0xFFFFFF, 0.14).setStroke(); pill.lineWidth = 1.5; pill.stroke()
        col(0x8FD9B6).setFill()
        NSBezierPath(ovalIn: NSRect(x: px + 30, y: py + ph / 2 - 8, width: 16, height: 16)).fill()
        text(cap, size: 38, weight: .semibold, color: col(0xF4F4F5), centerX: px + 30 + 16 + 14 + tw / 2, top: 36 + (ph - 46) / 2)
    }, String(format: "cap%02d.png", i + 1))
}

func icon(_ c: CGContext, size: CGFloat, centerX: CGFloat, top: CGFloat) {
    guard let img = NSImage(contentsOfFile: iconPath) else { return }
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -14), blur: 60, color: col(0x8FD9B6, 0.35).cgColor)
    img.draw(in: NSRect(x: centerX - size / 2, y: H - top - size, width: size, height: size))
    c.restoreGState()
}

// Intro
save(canvas(W, H) { c in
    background(c)
    icon(c, size: 190, centerX: W / 2, top: 190)
    text("Coran", size: 124, family: "Literata", weight: .semibold, color: col(0xF4F4F5), top: 420, tracking: -2)
    text("Le Coran, simplement.", size: 46, weight: .medium, color: col(0x8E8E93), top: 590)
    text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", size: 72, family: "Amiri Quran", color: col(0x8FD9B6), top: 700, rtl: true)
}, "intro.png")

// Outro
save(canvas(W, H) { c in
    background(c)
    icon(c, size: 150, centerX: W / 2, top: 150)
    text("Coran pour Mac", size: 96, family: "Literata", weight: .semibold, color: col(0xF4F4F5), top: 350, tracking: -1.5)
    text("Gratuit · sans compte · open source", size: 40, weight: .medium, color: col(0x8E8E93), top: 490)
    let url = "vf501d8k0u-coran.vercel.app"
    let tw = NSAttributedString(string: url, attributes: [.font: font("Inter", 44, .bold)]).size().width
    let pw = tw + 100, ph: CGFloat = 92
    let pill = NSBezierPath(roundedRect: NSRect(x: (W - pw) / 2, y: H - 640 - ph, width: pw, height: ph), xRadius: 26, yRadius: 26)
    col(0x8FD9B6).setFill(); pill.fill()
    text(url, size: 44, weight: .bold, color: col(0x06130D), top: 640 + (ph - 54) / 2)
    text("Puce Apple (M1 ou plus récent) · macOS 14", size: 30, color: col(0x8E8E93), top: 790)
    text("github.com/gaissepro/coran-mac", size: 30, color: col(0x8E8E93), top: 840)
}, "outro.png")
print("ok")
