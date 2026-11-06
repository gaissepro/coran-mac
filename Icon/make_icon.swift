import AppKit
import CoreText

// Enregistre la police arabe du projet
let fontURL = URL(fileURLWithPath: CommandLine.arguments[1])
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
let outPath = CommandLine.arguments[2]

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
let ctxNS = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctxNS
let ctx = ctxNS.cgContext

func col(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}

// Forme « squircle » macOS : 824 px centrés dans 1024
let box = NSRect(x: 100, y: 100, width: 824, height: 824)
let path = NSBezierPath(roundedRect: box, xRadius: 186, yRadius: 186)

// Ombre portée
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34, color: NSColor.black.withAlphaComponent(0.45).cgColor)
col(0x0B0F0E).setFill(); path.fill()
ctx.restoreGState()

// Fond : dégradé vert très sombre
ctx.saveGState()
path.addClip()
let bg = NSGradient(colors: [col(0x14231D), col(0x0A0F0D)], atLocations: [0, 1], colorSpace: .sRGB)!
bg.draw(in: box, angle: -60)
// Halo mentholé derrière la lettre
let halo = NSGradient(colors: [col(0x8FD9B6, 0.30), col(0x8FD9B6, 0.0)], atLocations: [0, 1], colorSpace: .sRGB)!
halo.draw(fromCenter: NSPoint(x: 512, y: 540), radius: 0, toCenter: NSPoint(x: 512, y: 540), radius: 380, options: [])

// Motif discret : anneau d'étoile à 8 branches (rub el hizb) en filigrane
ctx.setStrokeColor(col(0x8FD9B6, 0.10).cgColor)
ctx.setLineWidth(3)
for rot in [0.0, 45.0] {
    ctx.saveGState()
    ctx.translateBy(x: 512, y: 540); ctx.rotate(by: CGFloat(rot) * .pi / 180)
    ctx.stroke(CGRect(x: -300, y: -300, width: 600, height: 600))
    ctx.restoreGState()
}
ctx.restoreGState()

// Lettre ق (début de « Coran » / « Qur'an ») en Amiri Quran, dégradé menthe -> pêche
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Amiri Quran", size: 600) ?? NSFont.systemFont(ofSize: 560),
    .foregroundColor: NSColor.white,
]
let letter = NSAttributedString(string: "ق", attributes: attrs)
let sz = letter.size()
let lp = NSPoint(x: 512 - sz.width / 2, y: 540 - sz.height / 2 + 185)

// Masque de la lettre -> dégradé
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
letter.draw(at: lp)
NSGraphicsContext.current!.cgContext.setBlendMode(.sourceIn)
let g = NSGradient(colors: [col(0xB5F0D2), col(0x8FD9B6), col(0xF6B47B)], atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
g.draw(in: NSRect(x: 0, y: 0, width: S, height: S), angle: -70)
img.unlockFocus()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: col(0x8FD9B6, 0.35).cgColor)
img.draw(in: NSRect(x: 0, y: 0, width: S, height: S))
ctx.restoreGState()

// Petit croissant en haut à droite
let moon = NSBezierPath()
moon.appendOval(in: NSRect(x: 715, y: 725, width: 80, height: 80))
let cut = NSBezierPath(ovalIn: NSRect(x: 736, y: 736, width: 72, height: 72))
ctx.saveGState()
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
col(0xF6B47B).setFill(); moon.fill()
ctx.setBlendMode(.clear); cut.fill()
ctx.endTransparencyLayer()
ctx.restoreGState()

// Liseré intérieur fin
ctx.saveGState()
path.addClip()
col(0xFFFFFF, 0.10).setStroke(); path.lineWidth = 3
let inner = NSBezierPath(roundedRect: box.insetBy(dx: 1.5, dy: 1.5), xRadius: 184, yRadius: 184); inner.lineWidth = 3; inner.stroke()
ctx.restoreGState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("ok")
