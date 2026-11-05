import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let themeURL = root.appendingPathComponent("Themes/Minimal-Soft-Black-75.cape")
var theme = try PropertyListSerialization.propertyList(from: Data(contentsOf: themeURL), format: nil) as! [String: Any]
var cursors = theme["Cursors"] as! [String: [String: Any]]
let approved = NSBitmapImageRep(data: try Data(contentsOf: root.appendingPathComponent("Preview/arrow-border/redrawn.png")))!
let approvedCG = approved.cgImage!
let originalReps = cursors["com.apple.coregraphics.Arrow"]!["Representations"] as! [Data]
var replacements: [Data] = []
for data in originalReps {
    let original = NSBitmapImageRep(data: data)!
    let w = original.pixelsWide, h = original.pixelsHigh
    if w == approved.pixelsWide && h == approved.pixelsHigh {
        replacements.append(try Data(contentsOf: root.appendingPathComponent("Preview/arrow-border/redrawn.png")))
        continue
    }
    let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(approvedCG, in: CGRect(x: 0, y: 0, width: w, height: h))
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    replacements.append(bitmap.representation(using: .png, properties: [:])!)
}
for key in ["com.apple.coregraphics.Arrow", "com.apple.coregraphics.ArrowS"] {
    cursors[key]!["Representations"] = replacements
    cursors[key]!["HotSpotX"] = 2.9
    cursors[key]!["HotSpotY"] = 2.0
}
theme["Cursors"] = cursors
try PropertyListSerialization.data(fromPropertyList: theme, format: .xml, options: 0).write(to: themeURL, options: .atomic)

let previewURL = root.appendingPathComponent("Themes/全套预览.png")
let old = NSBitmapImageRep(data: try Data(contentsOf: previewURL))!
let context = CGContext(data: nil, width: old.pixelsWide, height: old.pixelsHigh, bitsPerComponent: 8, bytesPerRow: old.pixelsWide * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.draw(old.cgImage!, in: CGRect(x: 0, y: 0, width: old.pixelsWide, height: old.pixelsHigh))
for row in 0...1 {
    let top = row * 528
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    let offset = (top * old.pixelsWide) * 4
    context.setFillColor(red: CGFloat(pixels[offset]) / 255, green: CGFloat(pixels[offset + 1]) / 255, blue: CGFloat(pixels[offset + 2]) / 255, alpha: 1)
    context.fill(CGRect(x: 0, y: old.pixelsHigh - top - 120, width: 120, height: 120))
    let y = CGFloat(old.pixelsHigh - top - 22 - 96)
    context.interpolationQuality = .high
    context.draw(approvedCG, in: CGRect(x: 22, y: y, width: 96, height: 96))
    let arrow = cursors["com.apple.coregraphics.Arrow"]!
    let hx = 22 + (arrow["HotSpotX"] as! Double) * 3
    let hy = Double(old.pixelsHigh - top - 22) - (arrow["HotSpotY"] as! Double) * 3
    context.setFillColor(NSColor.systemRed.cgColor)
    context.fillEllipse(in: CGRect(x: hx - 1.5, y: hy - 1.5, width: 3, height: 3))
}
try NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!.write(to: previewURL, options: .atomic)
print("Updated Arrow and ArrowS in all four resolutions; refreshed first preview tile on both backgrounds.")
