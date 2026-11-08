import AppKit
import CoreText
import SwiftUI
import WidgetKit

// The App Store screenshot framer. store/frame/make.sh builds it with the widget's views and runs
// it as: compose <raw screenshots dir> <fonts dir> <app icon> <out dir> <en|ru>
let args = CommandLine.arguments
let rawDir = args[1], fontDir = args[2], iconPath = args[3], outDir = args[4], lang = args[5]
for f in try! FileManager.default.contentsOfDirectory(atPath: fontDir) where f.hasSuffix(".ttf") {
    CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: fontDir + "/" + f) as CFURL, .process, nil)
}

let violet = Color(red: 0xB9 / 255, green: 0xA0 / 255, blue: 0xFF / 255)
let lime = Color(red: 0xC8 / 255, green: 0xF5 / 255, blue: 0x3C / 255)

struct Caption { let first: String; let second: String; let accent: Color }

/// 1320 × 2868: caption on top, a phone screen below, on black with a soft glow.
struct Page<Screen: View>: View {
    let caption: Caption
    let screen: Screen
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
            RadialGradient(
                colors: [caption.accent.opacity(0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.6), startRadius: 0, endRadius: 950
            )
            VStack(spacing: 0) {
                (Text(caption.first).foregroundColor(.white) + Text("\n") + Text(caption.second).foregroundColor(caption.accent))
                    .font(.custom("InterTight-ExtraBold", size: 100))
                    .kerning(-2.5)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 60)
                    .frame(height: 490)
                Bezel(content: screen)
            }
        }
        .frame(width: 1320, height: 2868)
    }
}

/// The screen with rounded corners in a thin dark bezel.
struct Bezel<Content: View>: View {
    let content: Content
    var body: some View {
        content
            .frame(width: 1056, height: 2294)
            .clipShape(RoundedRectangle(cornerRadius: 118, style: .continuous))
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 130, style: .continuous).fill(Color(white: 0.11)))
            .overlay(RoundedRectangle(cornerRadius: 130, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 2))
    }
}

/// A widget rendered by the widget's own view, sharp at [scale].
@MainActor
func widgetImage(_ entry: CountdownEntry, _ family: WidgetFamily, scale: CGFloat) -> NSImage {
    let size = family == .systemSmall ? CGSize(width: 170, height: 170) : CGSize(width: 364, height: 170)
    let view = WeekCounterWidgetEntryView(entry: entry, family: family)
        .padding(16)
        .frame(width: size.width, height: size.height)
        .background(Palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .tint(Palette.violet)
        .environment(\.colorScheme, .dark)
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    return NSImage(cgImage: renderer.cgImage!, size: NSSize(width: size.width * scale, height: size.height * scale))
}

/// A home screen with the widgets and the app icon.
struct WidgetsScreen: View {
    let medium: NSImage, small1: NSImage, small2: NSImage, icon: NSImage
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.13, blue: 0.40), Color(red: 0.05, green: 0.04, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 64) {
                Image(nsImage: medium)
                HStack(spacing: 56) { Image(nsImage: small1); Image(nsImage: small2) }
                VStack(spacing: 16) {
                    Image(nsImage: icon).resizable().frame(width: 190, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 43, style: .continuous))
                    Text("Orbity").font(.custom("Inter-SemiBold", size: 38)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 56)
            }
        }
    }
}

@MainActor
func save(_ view: some View, _ name: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    let image = renderer.cgImage!
    // Opaque, like the screenshots App Store Connect expects.
    let ctx = CGContext(
        data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    print("saved \(lang)/\(name).png \(image.width)x\(image.height)")
}

let ru = lang == "ru"
let captions: [String: Caption] = ru ? [
    "week": Caption(first: "Смотрите, как", second: "наполняется неделя", accent: violet),
    "widgets": Caption(first: "Отсчёт прямо", second: "на экране «Домой»", accent: violet),
    "weekend": Caption(first: "Каждые выходные —", second: "праздник", accent: lime),
    "calendar": Caption(first: "Праздники и выходные", second: "уже в календаре", accent: lime),
    "awards": Caption(first: "Награда", second: "за каждую неделю", accent: violet),
] : [
    "week": Caption(first: "Watch your week", second: "fill up", accent: violet),
    "widgets": Caption(first: "Your countdown", second: "on the home screen", accent: violet),
    "weekend": Caption(first: "Every weekend", second: "gets a party", accent: lime),
    "calendar": Caption(first: "Holidays and days off", second: "built in", accent: lime),
    "awards": Caption(first: "A badge for", second: "every week", accent: violet),
]

let now = Date()
let work = CountdownEntry(
    date: now, title: ru ? "До выходных" : "Weekend in",
    subtitle: ru ? "пт 18:00 · 2 дня отдыха" : "Fri 18:00 · 2 days off",
    secondary: nil, days: 1, dayShort: ru ? "д" : "d",
    timerEnd: now.addingTimeInterval(3 * 3600), fill: 0.74, mode: .work
)
let off = CountdownEntry(
    date: now, title: ru ? "Вы отдыхаете!" : "You're off!",
    subtitle: ru ? "На работу: пн 09:00" : "Back to work Mon 09:00",
    secondary: nil, days: 1, dayShort: ru ? "д" : "d",
    timerEnd: now.addingTimeInterval(21 * 3600), fill: 0.71, mode: .weekend
)

MainActor.assumeIsolated {
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    func shot(_ name: String) -> some View {
        Image(nsImage: NSImage(contentsOfFile: "\(rawDir)/\(name).png")!).resizable()
    }
    let widgets = WidgetsScreen(
        medium: widgetImage(work, .systemMedium, scale: 2.6),
        small1: widgetImage(work, .systemSmall, scale: 2.6),
        small2: widgetImage(off, .systemSmall, scale: 2.6),
        icon: NSImage(contentsOfFile: iconPath)!
    )
    save(Page(caption: captions["week"]!, screen: shot("week")), "1-week")
    save(Page(caption: captions["widgets"]!, screen: widgets), "2-widgets")
    save(Page(caption: captions["weekend"]!, screen: shot("weekend")), "3-weekend")
    save(Page(caption: captions["calendar"]!, screen: shot("calendar")), "4-calendar")
    save(Page(caption: captions["awards"]!, screen: shot("awards")), "5-awards")
}
