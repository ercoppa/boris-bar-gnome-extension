import Cocoa

// Usage: swift make_icon.swift <input.svg> <output_dir> <sizes...>
let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: make_icon.swift <svg> <outdir> <size1> [size2...]")
    exit(1)
}
let svgPath = args[1]
let outDir = args[2]
let sizes = args[3...].compactMap { Int($0) }

guard let img = NSImage(contentsOfFile: svgPath) else {
    print("can't load SVG"); exit(1)
}

for size in sizes {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 32)!
    rep.size = NSSize(width: s, height: s)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    img.draw(in: NSRect(x: 0, y: 0, width: s, height: s),
             from: .zero,
             operation: .sourceOver,
             fraction: 1.0,
             respectFlipped: true,
             hints: [.interpolation: NSImageInterpolation.high.rawValue])
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    let out = "\(outDir)/icon_\(size).png"
    try! data.write(to: URL(fileURLWithPath: out))
    print(out)
}
