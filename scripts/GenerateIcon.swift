import AppKit
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor(calibratedRed: 0.063, green: 0.067, blue: 0.078, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
let lime = NSColor(calibratedRed: 0.65, green: 0.91, blue: 0.63, alpha: 1)
let circle = NSBezierPath(ovalIn: NSRect(x: 225, y: 202, width: 574, height: 574))
circle.lineWidth = 52
lime.setStroke()
circle.stroke()
let top = NSBezierPath(roundedRect: NSRect(x: 422, y: 838, width: 180, height: 48), xRadius: 24, yRadius: 24)
lime.setFill()
top.fill()
let stem = NSBezierPath(roundedRect: NSRect(x: 488, y: 779, width: 48, height: 92), xRadius: 12, yRadius: 12)
stem.fill()
let hand = NSBezierPath()
hand.move(to: NSPoint(x: 512, y: 489))
hand.line(to: NSPoint(x: 512, y: 669))
hand.move(to: NSPoint(x: 512, y: 489))
hand.line(to: NSPoint(x: 637, y: 410))
hand.lineWidth = 42
hand.lineCapStyle = .round
hand.stroke()
NSBezierPath(ovalIn: NSRect(x: 478, y: 455, width: 68, height: 68)).fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot render app icon")
}
let folder = URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
try png.write(to: folder.appendingPathComponent("AppIcon.png"))
print("Generated 1024px app icon")
