import SwiftUI

// MARK: - Color Init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3: (a,r,g,b) = (255, (int>>8)*17, (int>>4&0xF)*17, (int&0xF)*17)
        case 6: (a,r,g,b) = (255, int>>16, int>>8&0xFF, int&0xFF)
        case 8: (a,r,g,b) = (int>>24, int>>16&0xFF, int>>8&0xFF, int&0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    static func planetColor(_ body: CelestialBody) -> Color {
        switch body {
        case .sun:     return Color(hex: "F4A940")
        case .moon:    return Color(hex: "D6E4F0")
        case .mars:    return Color(hex: "E05252")
        case .mercury: return Color(hex: "5BAD72")
        case .jupiter: return Color(hex: "F5C542")
        case .venus:   return Color(hex: "F48FB1")
        case .saturn:  return Color(hex: "8FA8C8")
        case .rahu:    return Color(hex: "A97DC8")
        case .ketu:    return Color(hex: "C8956A")
        }
    }
}

// MARK: - Color Scheme

struct CosmicColorScheme: Sendable {
    let id: String
    let displayName: String
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let onSurface: Color
    let gradientTop: Color
    let gradientBottom: Color
    let isLight: Bool

    var colorScheme: ColorScheme { isLight ? .light : .dark }

    /// Explicit semantic roles prevent an already-presented sheet from retaining
    /// dark system label colors while the user switches to a light app theme.
    /// Dark variants continue using the existing system semantics unchanged.
    var semanticPrimaryText: Color { onSurface }
    var semanticSecondaryText: Color { onSurface.opacity(isLight ? 0.80 : 0.82) }
    var semanticTertiaryText: Color { onSurface.opacity(isLight ? 0.70 : 0.72) }
    var semanticDivider: Color { isLight ? onSurface.opacity(0.16) : Color.white.opacity(0.10) }
    var semanticBorder: Color { isLight ? onSurface.opacity(0.22) : Color.white.opacity(0.10) }
    var semanticHighlight: Color { isLight ? onSurface.opacity(0.08) : Color.white.opacity(0.20) }
    /// Text and glyphs shown on a filled primary control. The app background is
    /// deliberately near-black for dark themes and near-white for light themes,
    /// so it preserves contrast as the primary accent changes across all six themes.
    var selectedControlForeground: Color { background }

    static let obsidianGold = CosmicColorScheme(
        id: "obsidian_gold", displayName: "Deep Sandhya",
        primary:         Color(hex: "F0B36E"),
        secondary:       Color(hex: "D66A47"),
        tertiary:        Color(hex: "9CB77D"),
        background:      Color(hex: "100703"),
        surface:         Color(hex: "211108"),
        surfaceElevated: Color(hex: "321A0D"),
        onSurface:       Color(hex: "FFF3E4"),
        gradientTop:     Color(hex: "090301"),
        gradientBottom:  Color(hex: "260D04"),
        isLight: false
    )

    static let midnightAurora = CosmicColorScheme(
        id: "midnight_aurora", displayName: "Temple Dawn",
        primary:         Color(hex: "F4C574"),
        secondary:       Color(hex: "C85F46"),
        tertiary:        Color(hex: "D99458"),
        background:      Color(hex: "150806"),
        surface:         Color(hex: "28110D"),
        surfaceElevated: Color(hex: "3B1B13"),
        onSurface:       Color(hex: "FFF2DF"),
        gradientTop:     Color(hex: "110503"),
        gradientBottom:  Color(hex: "351008"),
        isLight: false
    )

    static let celestialPlum = CosmicColorScheme(
        id: "celestial_plum", displayName: "Kumkum Night",
        primary:         Color(hex: "E8A764"),
        secondary:       Color(hex: "C84F62"),
        tertiary:        Color(hex: "D7B56B"),
        background:      Color(hex: "140508"),
        surface:         Color(hex: "260D13"),
        surfaceElevated: Color(hex: "39151D"),
        onSurface:       Color(hex: "FFF0E8"),
        gradientTop:     Color(hex: "100305"),
        gradientBottom:  Color(hex: "310811"),
        isLight: false
    )

    static let cloudDancer = CosmicColorScheme(
        id: "cloud_dancer", displayName: "Ghee Lamp Ivory",
        primary:         Color(hex: "98541F"),
        secondary:       Color(hex: "A43F32"),
        tertiary:        Color(hex: "5E7341"),
        background:      Color(hex: "FFF8E9"),
        surface:         Color(hex: "FFFCF4"),
        surfaceElevated: Color(hex: "F6E7C9"),
        onSurface:       Color(hex: "2B1C0F"),
        gradientTop:     Color(hex: "FFFDF5"),
        gradientBottom:  Color(hex: "F3D9AD"),
        isLight: true
    )

    static let mochaAura = CosmicColorScheme(
        id: "mocha_aura", displayName: "Sandalwood",
        primary:         Color(hex: "8A4C24"),
        secondary:       Color(hex: "9D4A38"),
        tertiary:        Color(hex: "667647"),
        background:      Color(hex: "FAF0DF"),
        surface:         Color(hex: "FFF9ED"),
        surfaceElevated: Color(hex: "EDDBBC"),
        onSurface:       Color(hex: "2C2116"),
        gradientTop:     Color(hex: "FFF9ED"),
        gradientBottom:  Color(hex: "E8CEAA"),
        isLight: true
    )

    static let celestialMist = CosmicColorScheme(
        id: "celestial_mist", displayName: "Lotus Ash",
        primary:         Color(hex: "7D4A32"),
        secondary:       Color(hex: "8A4F58"),
        tertiary:        Color(hex: "5C7055"),
        background:      Color(hex: "F4F0EA"),
        surface:         Color(hex: "FCFAF6"),
        surfaceElevated: Color(hex: "E8DED2"),
        onSurface:       Color(hex: "28201B"),
        gradientTop:     Color(hex: "FBF8F2"),
        gradientBottom:  Color(hex: "E4D6C8"),
        isLight: true
    )
}

// MARK: - Environment Key

struct CosmicThemeKey: EnvironmentKey {
    static let defaultValue = CosmicColorScheme.obsidianGold
}

extension EnvironmentValues {
    var cosmicTheme: CosmicColorScheme {
        get { self[CosmicThemeKey.self] }
        set { self[CosmicThemeKey.self] = newValue }
    }
}

// MARK: - Theme Variant

enum CosmicThemeVariant: String, CaseIterable, Identifiable {
    case cosmicDark   = "cosmicDark"
    case nebulaBlue   = "nebulaBlue"
    case vedicSaffron = "vedicSaffron"
    case lunarSilver  = "lunarSilver"
    case solarGold    = "solarGold"
    case auroraGreen  = "auroraGreen"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cosmicDark:   return "Deep Sandhya"
        case .nebulaBlue:   return "Temple Dawn"
        case .vedicSaffron: return "Kumkum Night"
        case .lunarSilver:  return "Ghee Lamp Ivory"
        case .solarGold:    return "Sandalwood"
        case .auroraGreen:  return "Lotus Ash"
        }
    }
}

extension CosmicThemeVariant {
    var colorScheme: CosmicColorScheme {
        switch self {
        case .cosmicDark:   return .obsidianGold
        case .nebulaBlue:   return .midnightAurora
        case .vedicSaffron: return .celestialPlum
        case .lunarSilver:  return .cloudDancer
        case .solarGold:    return .mochaAura
        case .auroraGreen:  return .celestialMist
        }
    }
}

// MARK: - Ceremonial Background

struct RitualSanctuaryBackground: View {
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.background

                Image("RitualSanctuaryBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .saturation(theme.isLight ? 0.72 : 0.92)
                    .contrast(theme.isLight ? 0.88 : 1.02)
                    .opacity(imageOpacity)

                LinearGradient(
                    colors: readabilityVeil,
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var imageOpacity: Double {
        if reduceTransparency {
            return theme.isLight ? 0.22 : 0.44
        }
        return theme.isLight ? 0.42 : 0.78
    }

    private var readabilityVeil: [Color] {
        if theme.isLight {
            return [
                theme.gradientTop.opacity(0.84),
                theme.background.opacity(0.72),
                theme.gradientBottom.opacity(0.86)
            ]
        }
        return [
            Color.black.opacity(0.34),
            theme.background.opacity(0.30),
            theme.gradientBottom.opacity(0.62)
        ]
    }
}

// MARK: - Ceremonial Surface

struct CosmicGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let accentBorder: Bool
    @ViewBuilder let content: () -> Content
    @Environment(\.cosmicTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(cornerRadius: CGFloat = 26, accentBorder: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.accentBorder = accentBorder
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .background(
                theme.surface.opacity(reduceTransparency ? 1.0 : (theme.isLight ? 0.96 : 0.82)),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderGradient, lineWidth: accentBorder ? 1.0 : 0.6)
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, theme.primary.opacity(accentBorder ? 0.62 : 0.24), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                    .frame(height: 1)
                    .padding(.horizontal, cornerRadius)
                    .padding(.top, 1)
            }
            .shadow(
                color: theme.isLight ? theme.onSurface.opacity(0.08) : Color.black.opacity(0.24),
                radius: accentBorder ? 18 : 10,
                y: accentBorder ? 8 : 4
            )
    }

    private var borderGradient: LinearGradient {
        accentBorder
            ? LinearGradient(colors: [theme.primary.opacity(0.55), theme.tertiary.opacity(0.25)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [theme.semanticBorder, theme.semanticBorder.opacity(0.28)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Expandable Card

struct CosmicExpandableCard<Header: View, Detail: View>: View {
    let cornerRadius: CGFloat
    @State private var isExpanded: Bool
    @ViewBuilder let header: () -> Header
    @ViewBuilder let detail: () -> Detail
    @Environment(\.cosmicTheme) private var theme

    init(
        cornerRadius: CGFloat = 16,
        initiallyExpanded: Bool = false,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.cornerRadius = cornerRadius
        self._isExpanded = State(initialValue: initiallyExpanded)
        self.header = header
        self.detail = detail
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.1)) { isExpanded.toggle() }
            } label: {
                HStack {
                    header()
                    Spacer()
                    CosmicIcon(.chevron, size: 13, color: .secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(duration: 0.35, bounce: 0.1), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .padding(16)

            if isExpanded {
                Divider()
                    .overlay(LinearGradient(
                        colors: [theme.primary.opacity(0.4), theme.tertiary.opacity(0.2)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                detail()
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    isExpanded
                        ? LinearGradient(colors: [theme.primary.opacity(0.55), theme.tertiary.opacity(0.25)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [theme.semanticBorder, theme.semanticBorder.opacity(0.28)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isExpanded ? 1.0 : 0.6
                )
        )
    }
}

// MARK: - Section Header

struct CosmicSectionHeader: View {
    let title: String
    let icon: String
    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(theme.primary)
                .frame(width: 3, height: 14)
            CosmicIcon(name: icon, size: 15)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.serif)
                .foregroundStyle(theme.semanticPrimaryText)
            Spacer()
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Bespoke Icons

enum CosmicGlyph {
    case chart, orbit, vedic, remedy, bot, warning, chakra, heart
    case clock, lifetime, varga, bindu, settings, search, person, location
    case add, document, check, chevron, info, waveform, play, stop, send
    case lock, cpu, tap, moon, sun, star, sparkle, house, strength, generic

    init(systemName: String) {
        switch systemName {
        case "chart.pie.fill", "chart.xyaxis.line", "chart.line.uptrend.xyaxis", "circle.and.line.horizontal", "square.on.square.dashed":
            self = .chart
        case "sparkles", "sparkle", "moon.stars.fill":
            self = .sparkle
        case "eye.fill", "hand.raised.fill":
            self = .vedic
        case "cross.circle.fill", "leaf.fill":
            self = .remedy
        case "bubble.left.fill", "bubble.left.and.text.bubble.right.fill":
            self = .bot
        case "exclamationmark.triangle.fill", "exclamationmark.triangle":
            self = .warning
        case "circle.hexagonpath.fill":
            self = .chakra
        case "heart.fill":
            self = .heart
        case "clock.fill", "clock", "clock.badge.checkmark.fill":
            self = .clock
        case "scroll.fill":
            self = .lifetime
        case "square.grid.2x2.fill", "square.grid.2x2", "square.grid.3x3.fill":
            self = .varga
        case "grid", "circle.grid.cross.fill", "divide.circle.fill", "list.number":
            self = .bindu
        case "gearshape.fill":
            self = .settings
        case "magnifyingglass":
            self = .search
        case "person.fill", "person.3.fill", "person.crop.circle.fill":
            self = .person
        case "mappin.circle.fill":
            self = .location
        case "person.badge.plus":
            self = .add
        case "doc.richtext":
            self = .document
        case "checkmark", "checkmark.circle.fill", "checkmark.seal.fill":
            self = .check
        case "chevron.down", "chevron.up":
            self = .chevron
        case "info.circle":
            self = .info
        case "waveform", "waveform.path", "waveform.badge.magnifyingglass":
            self = .waveform
        case "play.circle.fill":
            self = .play
        case "stop.circle.fill":
            self = .stop
        case "paperplane.fill":
            self = .send
        case "lock.shield.fill", "lock.fill", "wifi.slash":
            self = .lock
        case "cpu.fill", "function":
            self = .cpu
        case "hand.tap.fill":
            self = .tap
        case "moon.fill":
            self = .moon
        case "sun.max.fill":
            self = .sun
        case "star.fill", "staroflife":
            self = .star
        case "house.fill":
            self = .house
        case "chart.bar.fill", "chart.bar.xaxis", "bolt.fill":
            self = .strength
        default:
            self = .generic
        }
    }
}

struct CosmicIcon: View {
    let glyph: CosmicGlyph
    let size: CGFloat
    var color: Color?

    @Environment(\.cosmicTheme) private var theme

    init(_ glyph: CosmicGlyph, size: CGFloat = 22, color: Color? = nil) {
        self.glyph = glyph
        self.size = size
        self.color = color
    }

    init(name: String, size: CGFloat = 22, color: Color? = nil) {
        self.glyph = CosmicGlyph(systemName: name)
        self.size = size
        self.color = color
    }

    var body: some View {
        let accent = color ?? theme.primary
        Canvas { ctx, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let rect = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            let stroke = StrokeStyle(lineWidth: max(1.25, size * 0.075), lineCap: .round, lineJoin: .round)
            let fine = StrokeStyle(lineWidth: max(0.9, size * 0.052), lineCap: .round, lineJoin: .round)

            func strokePath(_ path: Path, opacity: Double = 1, style: StrokeStyle? = nil) {
                ctx.stroke(path, with: .color(accent.opacity(opacity)), style: style ?? stroke)
            }

            func fillPath(_ path: Path, opacity: Double = 1) {
                ctx.fill(path, with: .color(accent.opacity(opacity)))
            }

            func line(_ a: CGPoint, _ b: CGPoint) {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                strokePath(path)
            }

            func circle(_ rect: CGRect, opacity: Double = 1, style: StrokeStyle? = nil) {
                strokePath(Path(ellipseIn: rect), opacity: opacity, style: style)
            }

            func dot(_ point: CGPoint, radius: CGFloat, opacity: Double = 1) {
                fillPath(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), opacity: opacity)
            }

            switch glyph {
            case .chart:
                var diamond = Path()
                diamond.move(to: CGPoint(x: w * 0.5, y: h * 0.10))
                diamond.addLine(to: CGPoint(x: w * 0.88, y: h * 0.5))
                diamond.addLine(to: CGPoint(x: w * 0.5, y: h * 0.90))
                diamond.addLine(to: CGPoint(x: w * 0.12, y: h * 0.5))
                diamond.closeSubpath()
                strokePath(diamond)
                line(CGPoint(x: w * 0.18, y: h * 0.5), CGPoint(x: w * 0.82, y: h * 0.5))
                line(CGPoint(x: w * 0.5, y: h * 0.16), CGPoint(x: w * 0.5, y: h * 0.84))
            case .orbit:
                circle(rect, opacity: 0.82)
                circle(rect.insetBy(dx: w * 0.18, dy: h * 0.18), opacity: 0.42, style: fine)
                dot(CGPoint(x: w * 0.78, y: h * 0.30), radius: size * 0.08)
            case .vedic:
                var eye = Path()
                eye.move(to: CGPoint(x: w * 0.10, y: h * 0.52))
                eye.addQuadCurve(to: CGPoint(x: w * 0.90, y: h * 0.52), control: CGPoint(x: w * 0.5, y: h * 0.18))
                eye.addQuadCurve(to: CGPoint(x: w * 0.10, y: h * 0.52), control: CGPoint(x: w * 0.5, y: h * 0.86))
                strokePath(eye)
                circle(CGRect(x: w * 0.38, y: h * 0.38, width: w * 0.24, height: h * 0.24))
                dot(CGPoint(x: w * 0.5, y: h * 0.5), radius: size * 0.045)
            case .remedy:
                var leaf = Path()
                leaf.move(to: CGPoint(x: w * 0.18, y: h * 0.68))
                leaf.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.18), control: CGPoint(x: w * 0.28, y: h * 0.22))
                leaf.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.76), control: CGPoint(x: w * 0.92, y: h * 0.48))
                leaf.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.68), control: CGPoint(x: w * 0.42, y: h * 0.86))
                strokePath(leaf)
                line(CGPoint(x: w * 0.24, y: h * 0.66), CGPoint(x: w * 0.70, y: h * 0.36))
            case .bot:
                let bubble = Path(roundedRect: rect.insetBy(dx: 0, dy: h * 0.08), cornerRadius: size * 0.18)
                strokePath(bubble)
                dot(CGPoint(x: w * 0.38, y: h * 0.50), radius: size * 0.035)
                dot(CGPoint(x: w * 0.62, y: h * 0.50), radius: size * 0.035)
                line(CGPoint(x: w * 0.42, y: h * 0.66), CGPoint(x: w * 0.58, y: h * 0.66))
            case .warning:
                var tri = Path()
                tri.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
                tri.addLine(to: CGPoint(x: w * 0.88, y: h * 0.82))
                tri.addLine(to: CGPoint(x: w * 0.12, y: h * 0.82))
                tri.closeSubpath()
                strokePath(tri)
                line(CGPoint(x: w * 0.5, y: h * 0.36), CGPoint(x: w * 0.5, y: h * 0.58))
                dot(CGPoint(x: w * 0.5, y: h * 0.70), radius: size * 0.035)
            case .chakra:
                circle(rect)
                circle(rect.insetBy(dx: w * 0.18, dy: h * 0.18), opacity: 0.62, style: fine)
                for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
                    line(CGPoint(x: w * 0.5, y: h * 0.5), CGPoint(x: w * (0.5 + 0.36 * cos(angle)), y: h * (0.5 + 0.36 * sin(angle))))
                }
            case .heart:
                var heart = Path()
                heart.move(to: CGPoint(x: w * 0.5, y: h * 0.82))
                heart.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.38), control1: CGPoint(x: w * 0.24, y: h * 0.66), control2: CGPoint(x: w * 0.10, y: h * 0.52))
                heart.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.28), control1: CGPoint(x: w * 0.20, y: h * 0.12), control2: CGPoint(x: w * 0.44, y: h * 0.18))
                heart.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.38), control1: CGPoint(x: w * 0.56, y: h * 0.18), control2: CGPoint(x: w * 0.80, y: h * 0.12))
                heart.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.82), control1: CGPoint(x: w * 0.90, y: h * 0.54), control2: CGPoint(x: w * 0.76, y: h * 0.66))
                strokePath(heart)
            case .clock:
                circle(rect)
                line(CGPoint(x: w * 0.5, y: h * 0.5), CGPoint(x: w * 0.5, y: h * 0.28))
                line(CGPoint(x: w * 0.5, y: h * 0.5), CGPoint(x: w * 0.67, y: h * 0.58))
            case .lifetime:
                var scroll = Path()
                scroll.move(to: CGPoint(x: w * 0.25, y: h * 0.18))
                scroll.addLine(to: CGPoint(x: w * 0.74, y: h * 0.18))
                scroll.addLine(to: CGPoint(x: w * 0.74, y: h * 0.82))
                scroll.addLine(to: CGPoint(x: w * 0.25, y: h * 0.82))
                scroll.closeSubpath()
                strokePath(scroll)
                line(CGPoint(x: w * 0.35, y: h * 0.40), CGPoint(x: w * 0.64, y: h * 0.40))
                line(CGPoint(x: w * 0.35, y: h * 0.58), CGPoint(x: w * 0.60, y: h * 0.58))
            case .varga:
                for row in 0..<2 {
                    for col in 0..<2 {
                        strokePath(Path(CGRect(x: w * (0.18 + CGFloat(col) * 0.34), y: h * (0.18 + CGFloat(row) * 0.34), width: w * 0.24, height: h * 0.24)), opacity: 0.9, style: fine)
                    }
                }
            case .bindu:
                for row in 0..<3 {
                    for col in 0..<3 {
                        dot(CGPoint(x: w * (0.28 + CGFloat(col) * 0.22), y: h * (0.28 + CGFloat(row) * 0.22)), radius: size * 0.035, opacity: row == col ? 1 : 0.5)
                    }
                }
            case .settings:
                circle(rect.insetBy(dx: w * 0.16, dy: h * 0.16))
                for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                    line(CGPoint(x: w * (0.5 + 0.24 * cos(angle)), y: h * (0.5 + 0.24 * sin(angle))), CGPoint(x: w * (0.5 + 0.40 * cos(angle)), y: h * (0.5 + 0.40 * sin(angle))))
                }
            case .search:
                circle(CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.46, height: h * 0.46))
                line(CGPoint(x: w * 0.58, y: h * 0.58), CGPoint(x: w * 0.84, y: h * 0.84))
            case .person:
                circle(CGRect(x: w * 0.36, y: h * 0.16, width: w * 0.28, height: h * 0.28))
                var shoulders = Path()
                shoulders.move(to: CGPoint(x: w * 0.18, y: h * 0.82))
                shoulders.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.82), control: CGPoint(x: w * 0.5, y: h * 0.52))
                strokePath(shoulders)
            case .location:
                var pin = Path()
                pin.move(to: CGPoint(x: w * 0.5, y: h * 0.88))
                pin.addCurve(to: CGPoint(x: w * 0.24, y: h * 0.42), control1: CGPoint(x: w * 0.34, y: h * 0.66), control2: CGPoint(x: w * 0.24, y: h * 0.58))
                pin.addCurve(to: CGPoint(x: w * 0.76, y: h * 0.42), control1: CGPoint(x: w * 0.24, y: h * 0.18), control2: CGPoint(x: w * 0.76, y: h * 0.18))
                pin.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control1: CGPoint(x: w * 0.76, y: h * 0.58), control2: CGPoint(x: w * 0.66, y: h * 0.66))
                strokePath(pin)
                dot(CGPoint(x: w * 0.5, y: h * 0.42), radius: size * 0.04)
            case .add:
                circle(rect, opacity: 0.78)
                line(CGPoint(x: w * 0.5, y: h * 0.32), CGPoint(x: w * 0.5, y: h * 0.68))
                line(CGPoint(x: w * 0.32, y: h * 0.5), CGPoint(x: w * 0.68, y: h * 0.5))
            case .document:
                strokePath(Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.14, width: w * 0.48, height: h * 0.72), cornerRadius: size * 0.06))
                line(CGPoint(x: w * 0.36, y: h * 0.40), CGPoint(x: w * 0.64, y: h * 0.40))
                line(CGPoint(x: w * 0.36, y: h * 0.56), CGPoint(x: w * 0.62, y: h * 0.56))
            case .check:
                var check = Path()
                check.move(to: CGPoint(x: w * 0.20, y: h * 0.52))
                check.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
                check.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))
                strokePath(check)
            case .chevron:
                var chev = Path()
                chev.move(to: CGPoint(x: w * 0.24, y: h * 0.38))
                chev.addLine(to: CGPoint(x: w * 0.5, y: h * 0.64))
                chev.addLine(to: CGPoint(x: w * 0.76, y: h * 0.38))
                strokePath(chev)
            case .info:
                circle(rect)
                line(CGPoint(x: w * 0.5, y: h * 0.45), CGPoint(x: w * 0.5, y: h * 0.70))
                dot(CGPoint(x: w * 0.5, y: h * 0.30), radius: size * 0.035)
            case .waveform:
                var wave = Path()
                wave.move(to: CGPoint(x: w * 0.12, y: h * 0.56))
                wave.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.44), control1: CGPoint(x: w * 0.30, y: h * 0.16), control2: CGPoint(x: w * 0.66, y: h * 0.84))
                strokePath(wave)
                line(CGPoint(x: w * 0.24, y: h * 0.30), CGPoint(x: w * 0.24, y: h * 0.70))
                line(CGPoint(x: w * 0.76, y: h * 0.30), CGPoint(x: w * 0.76, y: h * 0.70))
            case .play:
                circle(rect)
                var play = Path()
                play.move(to: CGPoint(x: w * 0.42, y: h * 0.32))
                play.addLine(to: CGPoint(x: w * 0.70, y: h * 0.5))
                play.addLine(to: CGPoint(x: w * 0.42, y: h * 0.68))
                play.closeSubpath()
                fillPath(play)
            case .stop:
                circle(rect)
                fillPath(Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.38, width: w * 0.24, height: h * 0.24), cornerRadius: size * 0.03))
            case .send:
                var send = Path()
                send.move(to: CGPoint(x: w * 0.14, y: h * 0.50))
                send.addLine(to: CGPoint(x: w * 0.86, y: h * 0.18))
                send.addLine(to: CGPoint(x: w * 0.68, y: h * 0.82))
                send.addLine(to: CGPoint(x: w * 0.46, y: h * 0.58))
                send.closeSubpath()
                strokePath(send)
            case .lock:
                strokePath(Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.44, width: w * 0.52, height: h * 0.36), cornerRadius: size * 0.06))
                var shackle = Path()
                shackle.move(to: CGPoint(x: w * 0.34, y: h * 0.44))
                shackle.addCurve(to: CGPoint(x: w * 0.66, y: h * 0.44), control1: CGPoint(x: w * 0.34, y: h * 0.18), control2: CGPoint(x: w * 0.66, y: h * 0.18))
                strokePath(shackle)
            case .cpu:
                strokePath(Path(roundedRect: rect, cornerRadius: size * 0.08))
                strokePath(Path(roundedRect: rect.insetBy(dx: w * 0.20, dy: h * 0.20), cornerRadius: size * 0.04), opacity: 0.65, style: fine)
            case .tap:
                circle(CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.30, height: h * 0.30), opacity: 0.5, style: fine)
                line(CGPoint(x: w * 0.48, y: h * 0.26), CGPoint(x: w * 0.70, y: h * 0.74))
                line(CGPoint(x: w * 0.70, y: h * 0.74), CGPoint(x: w * 0.54, y: h * 0.68))
            case .moon:
                var moon = Path()
                moon.addArc(center: CGPoint(x: w * 0.54, y: h * 0.48), radius: w * 0.32, startAngle: .degrees(105), endAngle: .degrees(255), clockwise: false)
                moon.addArc(center: CGPoint(x: w * 0.70, y: h * 0.48), radius: w * 0.30, startAngle: .degrees(235), endAngle: .degrees(125), clockwise: true)
                strokePath(moon)
            case .sun:
                circle(rect.insetBy(dx: w * 0.18, dy: h * 0.18))
                for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                    line(CGPoint(x: w * (0.5 + 0.34 * cos(angle)), y: h * (0.5 + 0.34 * sin(angle))), CGPoint(x: w * (0.5 + 0.45 * cos(angle)), y: h * (0.5 + 0.45 * sin(angle))))
                }
            case .star, .sparkle, .generic:
                var star = Path()
                star.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
                star.addLine(to: CGPoint(x: w * 0.58, y: h * 0.42))
                star.addLine(to: CGPoint(x: w * 0.88, y: h * 0.5))
                star.addLine(to: CGPoint(x: w * 0.58, y: h * 0.58))
                star.addLine(to: CGPoint(x: w * 0.5, y: h * 0.88))
                star.addLine(to: CGPoint(x: w * 0.42, y: h * 0.58))
                star.addLine(to: CGPoint(x: w * 0.12, y: h * 0.5))
                star.addLine(to: CGPoint(x: w * 0.42, y: h * 0.42))
                star.closeSubpath()
                strokePath(star)
            case .house:
                var house = Path()
                house.move(to: CGPoint(x: w * 0.18, y: h * 0.52))
                house.addLine(to: CGPoint(x: w * 0.5, y: h * 0.20))
                house.addLine(to: CGPoint(x: w * 0.82, y: h * 0.52))
                house.addLine(to: CGPoint(x: w * 0.72, y: h * 0.52))
                house.addLine(to: CGPoint(x: w * 0.72, y: h * 0.82))
                house.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
                house.addLine(to: CGPoint(x: w * 0.28, y: h * 0.52))
                house.closeSubpath()
                strokePath(house)
            case .strength:
                for i in 0..<3 {
                    let x = w * (0.24 + CGFloat(i) * 0.22)
                    let top = h * (0.68 - CGFloat(i) * 0.16)
                    strokePath(Path(roundedRect: CGRect(x: x, y: top, width: w * 0.12, height: h * 0.78 - top), cornerRadius: size * 0.03), opacity: 0.75 + Double(i) * 0.08, style: fine)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct CosmicTabLabel: View {
    let title: String
    let glyph: CosmicGlyph

    var body: some View {
        Label {
            Text(title)
        } icon: {
            CosmicIcon(glyph, size: 22)
        }
    }
}

// MARK: - Screen Header

struct CosmicScreenHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    var detail: String? = nil

    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.16))
                    .frame(width: 52, height: 52)
                    .blur(radius: 8)
                Circle()
                    .fill(theme.surfaceElevated.opacity(0.40))
                    .frame(width: 46, height: 46)
                CosmicIcon(name: icon, size: 21)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(theme.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: Capsule())
            }
        }
        .padding(16)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.surface.opacity(0.26))
                LinearGradient(
                    colors: [theme.primary.opacity(0.10), theme.tertiary.opacity(0.04), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.34), theme.semanticBorder.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }
}

// MARK: - Segmented Tabs

struct CosmicSegmentedTabs: View {
    let tabs: [(title: String, icon: String)]
    @Binding var selection: Int

    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        GlassEffectContainer {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs.indices, id: \.self) { i in
                        CosmicSegmentButton(
                            title: tabs[i].title,
                            icon: tabs[i].icon,
                            isSelected: selection == i
                        ) {
                            withAnimation(.spring(duration: 0.28, bounce: 0.12)) {
                                selection = i
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

private struct CosmicSegmentButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        if isSelected {
            Button(action: action) {
                segmentLabel
            }
            .buttonStyle(.glassProminent)
            .tint(theme.primary)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isSelected)
        } else {
            Button(action: action) {
                segmentLabel
            }
            .buttonStyle(.glass)
            .tint(theme.onSurface.opacity(0.80))
            .accessibilityLabel(title)
        }
    }

    private var segmentLabel: some View {
        HStack(spacing: 6) {
            if !icon.isEmpty {
                CosmicIcon(name: icon, size: 13)
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, icon.isEmpty ? 6 : 2)
        .frame(minHeight: 30)
    }
}

// MARK: - Empty State

struct CosmicEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.14))
                    .frame(width: 86, height: 86)
                    .blur(radius: 18)
                CosmicIcon(name: icon, size: 48)
            }

            VStack(spacing: 7) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.semanticPrimaryText)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(theme.semanticSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.glassProminent)
            }
        }
        .padding(28)
        .frame(maxWidth: 360)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.semanticBorder, lineWidth: 0.7)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Metric Tile

struct CosmicMetricTile: View {
    let label: String
    let value: String
    let icon: String
    var color: Color? = nil

    @Environment(\.cosmicTheme) private var theme

    var body: some View {
        let accent = color ?? theme.primary
        HStack(spacing: 9) {
            CosmicIcon(name: icon, size: 18, color: accent)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(theme.semanticTertiaryText)
                    .textCase(.uppercase)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.semanticPrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(accent.opacity(0.075), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 0.6)
        )
    }
}

// MARK: - Progress Ring

struct CosmicProgressRing: View {
    let progress: Double      // 0–1
    let planet: CelestialBody
    let size: CGFloat
    var lineWidth: CGFloat = 5

    var body: some View {
        let color = Color.planetColor(planet)
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color, color.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1.0, bounce: 0.1), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Planet Orb

struct CosmicOrb: View {
    let planet: CelestialBody
    let size: CGFloat
    var glowing: Bool = false

    var body: some View {
        let color = Color.planetColor(planet)
        ZStack {
            if glowing {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: size * 1.9, height: size * 1.9)
                    .blur(radius: size * 0.45)
            }
            Circle()
                .fill(RadialGradient(
                    colors: [color.opacity(0.28), color.opacity(0.06)],
                    center: .center, startRadius: 0, endRadius: size / 2
                ))
                .frame(width: size, height: size)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.65), color.opacity(0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .frame(width: size, height: size)
            Text(planet.symbol)
                .font(.system(size: size * 0.45))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Privacy Badge

struct PrivacyBadge: View {
    var body: some View {
        HStack(spacing: 7) {
            CosmicIcon(.lock, size: 15, color: .green)
            Text("100% On-Device  ·  No Data Shared  ·  No Account")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().stroke(Color.green.opacity(0.28), lineWidth: 0.6))
    }
}

// MARK: - Planet Tag

struct PlanetTag: View {
    let planet: CelestialBody

    var body: some View {
        HStack(spacing: 4) {
            Text(planet.symbol)
            Text(planet.rawValue).font(.caption)
        }
        .foregroundStyle(Color.planetColor(planet))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().stroke(Color.planetColor(planet).opacity(0.35), lineWidth: 0.5))
    }
}

// MARK: - Cosmic Badge

struct CosmicBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.40), lineWidth: 0.5))
    }
}

// MARK: - Stat Row

struct CosmicStatRow: View {
    let label: String
    let value: String
    var accent: Color = .secondary

    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(accent)
        }
    }
}

// MARK: - DMS Label

private func formatDMS(_ degrees: Double) -> String {
    let total = abs(degrees) * 3600
    let d = Int(total / 3600)
    let m = Int(total.truncatingRemainder(dividingBy: 3600) / 60)
    let s = Int(total.truncatingRemainder(dividingBy: 60))
    return "\(degrees < 0 ? "-" : "")\(d)°\(String(format: "%02d", m))′\(String(format: "%02d", s))″"
}

struct DMSLabel: View {
    let degrees: Double

    var body: some View {
        Text(formatDMS(degrees))
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Loading View

struct CosmicLoadingView: View {
    @Environment(\.cosmicTheme) private var theme
    @State private var rotation = 0.0
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                // Outer orbit ring
                Circle()
                    .stroke(theme.primary.opacity(0.07), lineWidth: 0.8)
                    .frame(width: 88, height: 88)
                // Orbiting dot
                Circle()
                    .fill(theme.primary.opacity(0.65))
                    .frame(width: 5, height: 5)
                    .offset(x: 44)
                    .rotationEffect(.degrees(rotation))
                // Arc track
                Circle()
                    .stroke(theme.primary.opacity(0.09), lineWidth: 2.5)
                    .frame(width: 62, height: 62)
                // Spinning arc
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary, theme.tertiary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(rotation))
                // Inner orbit ring
                Circle()
                    .stroke(theme.secondary.opacity(0.06), lineWidth: 0.6)
                    .frame(width: 38, height: 38)
                // Counter-rotating inner dot
                Circle()
                    .fill(theme.secondary.opacity(0.5))
                    .frame(width: 3, height: 3)
                    .offset(x: 19)
                    .rotationEffect(.degrees(-rotation * 1.4))
                // Center sigil
                Text("✦")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.tertiary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulse ? 1.18 : 0.88)
                    .opacity(pulse ? 1.0 : 0.65)
            }

            Text("Calculating chart…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
