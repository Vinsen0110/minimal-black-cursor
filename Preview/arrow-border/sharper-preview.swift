import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: root.appendingPathComponent("thin.png"))
let input = NSBitmapImageRep(data: data)!
let w = input.pixelsWide, h = input.pixelsHigh
let output = input.copy() as! NSBitmapImageRep
// Taper only the upper tip. Blend back to the unchanged contour below it.
for y in 0..<h {
    for x in 0..<w {
        let sy = y < 95 ? 95 - (95 - Double(y)) / 1.16 : Double(y)
        let taper = 1 - 0.38 * max(0, min(1, (90 - sy) / 60))
        let sx = 38 + (Double(x) - 38) / taper
        let ix = Int(floor(sx)), iy = Int(floor(sy))
        var rgba = [CGFloat](repeating: 0, count: 4)
        for dy in 0...1 {
            for dx in 0...1 {
                let xx = ix + dx, yy = iy + dy
                guard xx >= 0 && xx < w && yy >= 0 && yy < h else { continue }
                let c = input.colorAt(x: xx, y: yy)!.usingColorSpace(.deviceRGB)!
                let weight = CGFloat((dx == 0 ? 1 - (sx - Double(ix)) : sx - Double(ix)) * (dy == 0 ? 1 - (sy - Double(iy)) : sy - Double(iy)))
                rgba[0] += c.redComponent * c.alphaComponent * weight
                rgba[1] += c.greenComponent * c.alphaComponent * weight
                rgba[2] += c.blueComponent * c.alphaComponent * weight
                rgba[3] += c.alphaComponent * weight
            }
        }
        let a = rgba[3]
        output.setColor(NSColor(deviceRed: a > 0 ? rgba[0] / a : 0, green: a > 0 ? rgba[1] / a : 0, blue: a > 0 ? rgba[2] / a : 0, alpha: a), atX: x, y: y)
    }
}
let sharpData = output.representation(using: .png, properties: [:])!
try sharpData.write(to: root.appendingPathComponent("sharper.png"))
let images = [NSImage(data: data)!, NSImage(data: sharpData)!]
let canvas = NSImage(size: NSSize(width: 900, height: 620))
canvas.lockFocus()
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor) {
    (s as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color])
}
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 900, height: 620).fill()
text("箭头尖端对比 · 保留细白边", 30, 566, 25, .black)
text("左：当前已应用版     右：稍尖候选版（尚未应用）", 30, 533, 16, .darkGray)
for row in 0...1 {
    let bottom: CGFloat = row == 0 ? 285 : 40
    let dark = row == 1
    NSColor(calibratedWhite: dark ? 0.16 : 0.94, alpha: 1).setFill()
    NSRect(x: 20, y: bottom, width: 860, height: 235).fill()
    let color: NSColor = dark ? .white : .darkGray
    for col in 0...1 {
        let x: CGFloat = col == 0 ? 65 : 490
        text(col == 0 ? "当前版" : "稍尖版", x, bottom + 197, 18, color)
        images[col].draw(in: NSRect(x: x + 35, y: bottom - 12, width: 240, height: 240), from: .zero, operation: .sourceOver, fraction: 1)
        images[col].draw(in: NSRect(x: x + 230, y: bottom + 65, width: 32, height: 32), from: .zero, operation: .sourceOver, fraction: 1)
        text("放大细节", x + 35, bottom + 14, 12, color)
        text("小尺寸", x + 220, bottom + 43, 12, color)
    }
}
text("仅生成候选预览，主题文件与系统鼠标未更改。", 30, 12, 12, .darkGray)
canvas.unlockFocus()
try NSBitmapImageRep(data: canvas.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("箭头尖端对比.png"))
