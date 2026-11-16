import AppKit
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let rect = NSRect(x: 64, y: 64, width: 896, height: 896)
let outline = NSBezierPath(roundedRect: rect, xRadius: 205, yRadius: 205)
NSGradient(starting: NSColor(calibratedRed: 0.055, green: 0.16, blue: 0.29, alpha: 1),
           ending: NSColor(calibratedRed: 0.06, green: 0.64, blue: 0.65, alpha: 1))!.draw(in: outline, angle: 45)
NSColor.white.withAlphaComponent(0.13).setFill()
NSBezierPath(roundedRect: NSRect(x: 235, y: 287, width: 570, height: 360), xRadius: 90, yRadius: 90).fill()
NSColor.white.setStroke()
let bubble = NSBezierPath()
bubble.move(to: NSPoint(x: 285, y: 340))
bubble.line(to: NSPoint(x: 235, y: 270))
bubble.line(to: NSPoint(x: 235, y: 367))
bubble.curve(to: NSPoint(x: 205, y: 440), controlPoint1: NSPoint(x: 210, y: 380), controlPoint2: NSPoint(x: 205, y: 410))
bubble.line(to: NSPoint(x: 205, y: 650))
bubble.curve(to: NSPoint(x: 285, y: 730), controlPoint1: NSPoint(x: 205, y: 704), controlPoint2: NSPoint(x: 231, y: 730))
bubble.line(to: NSPoint(x: 695, y: 730))
bubble.curve(to: NSPoint(x: 775, y: 650), controlPoint1: NSPoint(x: 749, y: 730), controlPoint2: NSPoint(x: 775, y: 704))
bubble.line(to: NSPoint(x: 775, y: 440))
bubble.curve(to: NSPoint(x: 695, y: 360), controlPoint1: NSPoint(x: 775, y: 386), controlPoint2: NSPoint(x: 749, y: 360))
bubble.line(to: NSPoint(x: 360, y: 360))
bubble.lineWidth = 30
bubble.lineJoinStyle = .round
bubble.lineCapStyle = .round
bubble.stroke()
let bridge = NSBezierPath()
bridge.move(to: NSPoint(x: 318, y: 490))
bridge.curve(to: NSPoint(x: 662, y: 490), controlPoint1: NSPoint(x: 395, y: 660), controlPoint2: NSPoint(x: 585, y: 660))
bridge.lineWidth = 42
bridge.lineCapStyle = .round
bridge.stroke()
let deck = NSBezierPath()
deck.move(to: NSPoint(x: 320, y: 490)); deck.line(to: NSPoint(x: 660, y: 490))
deck.move(to: NSPoint(x: 425, y: 490)); deck.line(to: NSPoint(x: 425, y: 570))
deck.move(to: NSPoint(x: 555, y: 490)); deck.line(to: NSPoint(x: 555, y: 570))
deck.lineWidth = 24; deck.lineCapStyle = .round; deck.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
