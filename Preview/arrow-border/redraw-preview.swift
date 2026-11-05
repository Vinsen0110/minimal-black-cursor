import AppKit
import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: root.appendingPathComponent("thin.png"))
let input = NSBitmapImageRep(data: data)!
let w = input.pixelsWide, h = input.pixelsHigh
let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.draw(input.cgImage!, in: CGRect(x: 0, y: 0, width: w, height: h))
context.translateBy(x: 0, y: CGFloat(h))
context.scaleBy(x: 1, y: -1)
context.clip(to: CGRect(x: 0, y: 0, width: w, height: 76))
context.clear(CGRect(x: 0, y: 0, width: w, height: 76))
// Align the stroke centerlines with the existing straight edges.
let path = CGMutablePath()
path.move(to: CGPoint(x: 27.5, y: 150))
path.addLine(to: CGPoint(x: 27.5, y: 25))
path.addQuadCurve(to: CGPoint(x: 35, y: 22.4), control: CGPoint(x: 27.5, y: 14.9))
path.addLine(to: CGPoint(x: 162.6, y: 150))
path.closeSubpath()
context.addPath(path)
// Match the original bitmap's encoded fill exactly, avoiding a color-space seam.
let originalContext = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
originalContext.draw(input.cgImage!, in: CGRect(x: 0, y: 0, width: w, height: h))
let pixels = originalContext.data!.assumingMemoryBound(to: UInt8.self)
let offset = (70 * w + 45) * 4
context.setFillColor(red: CGFloat(pixels[offset]) / 255, green: CGFloat(pixels[offset + 1]) / 255, blue: CGFloat(pixels[offset + 2]) / 255, alpha: 1)
context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
context.setLineWidth(8)
context.setLineJoin(.round)
context.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: CGColor(gray: 0, alpha: 0.13))
context.drawPath(using: .fillStroke)
let output = NSBitmapImageRep(cgImage: context.makeImage()!)
let sharpData = output.representation(using: .png, properties: [:])!
try sharpData.write(to: root.appendingPathComponent("redrawn.png"))
let images = [NSImage(data: data)!, NSImage(data: sharpData)!]
let canvas = NSImage(size: NSSize(width: 900, height: 620))
canvas.lockFocus()
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor) {
    (s as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color])
}
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 900, height: 620).fill()
text("箭头尖端对比 · 保留细白边", 30, 566, 25, .black)
text("左：当前已应用版     右：直边尖端重绘版（尚未应用）", 30, 533, 16, .darkGray)
for row in 0...1 {
    let bottom: CGFloat = row == 0 ? 285 : 40
    let dark = row == 1
    NSColor(calibratedWhite: dark ? 0.16 : 0.94, alpha: 1).setFill()
    NSRect(x: 20, y: bottom, width: 860, height: 235).fill()
    let color: NSColor = dark ? .white : .darkGray
    for col in 0...1 {
        let x: CGFloat = col == 0 ? 65 : 490
        text(col == 0 ? "当前版" : "重绘版", x, bottom + 197, 18, color)
        images[col].draw(in: NSRect(x: x + 35, y: bottom - 12, width: 240, height: 240), from: .zero, operation: .sourceOver, fraction: 1)
        images[col].draw(in: NSRect(x: x + 230, y: bottom + 65, width: 32, height: 32), from: .zero, operation: .sourceOver, fraction: 1)
        text("放大细节", x + 35, bottom + 14, 12, color)
        text("小尺寸", x + 220, bottom + 43, 12, color)
    }
}
text("仅生成候选预览，主题文件与系统鼠标未更改。", 30, 12, 12, .darkGray)
canvas.unlockFocus()
try NSBitmapImageRep(data: canvas.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("箭头直边尖端对比.png"))
