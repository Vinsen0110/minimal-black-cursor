import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let source = NSImage(contentsOf: root.appendingPathComponent("original.png"))!
let input = NSBitmapImageRep(data: try Data(contentsOf: root.appendingPathComponent("original.png")))!
let width = input.pixelsWide
let height = input.pixelsHigh
let output = input.copy() as! NSBitmapImageRep

// Inset the outer silhouette by 0.3 logical points at this 10x resolution.
// Leave the dark fill intact; the white edge and its shadow move inward.
for y in 0..<height {
    for x in 0..<width {
        let color = input.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
        var alpha = color.alphaComponent
        if max(color.redComponent, color.greenComponent, color.blueComponent) > 0.5 || alpha < 0.95 {
            for dy in -3...3 {
                for dx in -3...3 where dx * dx + dy * dy <= 9 {
                    let nx = x + dx, ny = y + dy
                    let nearby: CGFloat = nx >= 0 && nx < width && ny >= 0 && ny < height ? input.colorAt(x: nx, y: ny)!.alphaComponent : 0
                    alpha = min(alpha, nearby)
                }
            }
        }
        output.setColor(NSColor(deviceRed: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: alpha), atX: x, y: y)
    }
}
try output.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("thin.png"))
let thin = NSImage(data: output.representation(using: .png, properties: [:])!)!

let canvas = NSImage(size: NSSize(width: 1000, height: 760))
canvas.lockFocus()
func fill(_ rect: NSRect, _ color: NSColor) { color.setFill(); rect.fill() }
func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor = .labelColor, bold: Bool = false) {
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size), .foregroundColor: color])
}
fill(NSRect(x: 0, y: 0, width: 1000, height: 760), NSColor(calibratedWhite: 0.97, alpha: 1))
text("普通箭头 · 白边细化对比", 40, 704, 27, .black, bold: true)
text("左：原版     右：白边减薄约 25%   ｜   黑色主体、箭头尺寸、点击位置不变", 40, 670, 16, .darkGray)
for (row, background) in [NSColor(calibratedWhite: 0.94, alpha: 1), NSColor(calibratedWhite: 0.16, alpha: 1)].enumerated() {
    let y: CGFloat = row == 0 ? 360 : 65
    let foreground: NSColor = row == 0 ? .darkGray : .white
    fill(NSRect(x: 30, y: y, width: 940, height: 280), background)
    text(row == 0 ? "浅色背景" : "深色背景", 50, y + 242, 15, foreground)
    for (column, image) in [source, thin].enumerated() {
        let x: CGFloat = column == 0 ? 135 : 590
        text(column == 0 ? "原版" : "细白边预览", x, y + 205, 19, foreground, bold: true)
        image.draw(in: NSRect(x: x + 30, y: y - 35, width: 240, height: 240), from: .zero, operation: .sourceOver, fraction: 1)
        image.draw(in: NSRect(x: x + 220, y: y + 90, width: 32, height: 32), from: .zero, operation: .sourceOver, fraction: 1)
        text("放大细节", x, y + 22, 13, foreground)
        text("接近实际大小", x + 210, y + 65, 12, foreground)
    }
}
text("仅为对比预览，尚未修改或应用主题。实际大小随屏幕和系统指针设置变化。", 40, 24, 13, .darkGray)
canvas.unlockFocus()
let rendered = NSBitmapImageRep(data: canvas.tiffRepresentation!)!
try rendered.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("箭头白边对比.png"))
