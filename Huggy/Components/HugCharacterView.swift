import SwiftUI

struct HugCharacterView: View {
    var hugType: HugType
    var isHugging: Bool
    var size: CGFloat = 120

    @State private var floatOffset: CGFloat = 0
    @State private var leftArmRotation: Double = -30
    @State private var rightArmRotation: Double = 30
    @State private var appeared = false

    private var tintColor: Color {
        hugType.color
    }

    private var tintGradient: LinearGradient {
        LinearGradient(
            colors: [tintColor.opacity(0.8), tintColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            floatingHearts

            // Left arm
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(tintColor.opacity(0.7))
                .frame(width: size * 0.18, height: size * 0.45)
                .offset(x: -size * 0.32, y: size * 0.05)
                .rotationEffect(.degrees(leftArmRotation), anchor: .top)

            // Right arm
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(tintColor.opacity(0.7))
                .frame(width: size * 0.18, height: size * 0.45)
                .offset(x: size * 0.32, y: size * 0.05)
                .rotationEffect(.degrees(rightArmRotation), anchor: .top)

            // Heart body
            HeartShape()
                .fill(tintGradient)
                .frame(width: size * 0.7, height: size * 0.65)

            // Face group
            faceView
        }
        .frame(width: size, height: size)
        .offset(y: floatOffset)
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                floatOffset = -6
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
            updateArmPose()
        }
        .onChange(of: isHugging) { _ in
            updateArmPose()
        }
    }

    private var faceView: some View {
        Group {
            // Eyes
            Circle()
                .fill(Color(hex: "3D1C12"))
                .frame(width: size * 0.065, height: size * 0.065)
                .offset(x: -size * 0.1, y: -size * 0.06)

            Circle()
                .fill(Color(hex: "3D1C12"))
                .frame(width: size * 0.065, height: size * 0.065)
                .offset(x: size * 0.1, y: -size * 0.06)

            // Cheek blush
            Circle()
                .fill(Color.pink.opacity(0.35))
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: -size * 0.18, y: size * 0.02)

            Circle()
                .fill(Color.pink.opacity(0.35))
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.18, y: size * 0.02)
        }
    }

    private var floatingHearts: some View {
        ForEach(0..<3, id: \.self) { index in
            FloatingHeart(
                tint: tintColor,
                size: size * 0.12,
                delay: Double(index) * 0.4
            )
            .offset(
                x: CGFloat(index - 1) * size * 0.28,
                y: -size * 0.35
            )
        }
    }

    private func updateArmPose() {
        let target = isHugging ? (-60.0, 60.0) : (-30.0, 30.0)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            leftArmRotation = target.0
            rightArmRotation = target.1
        }
    }
}

// MARK: - Heart Shape

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.25))

        // Left curve
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.0, y: h * -0.1),
            control2: CGPoint(x: w * 0.0, y: h * 0.7)
        )

        // Right curve
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.25),
            control1: CGPoint(x: w * 1.0, y: h * 0.7),
            control2: CGPoint(x: w * 1.0, y: h * -0.1)
        )

        return path
    }
}

// MARK: - Floating Heart

struct FloatingHeart: View {
    let tint: Color
    let size: CGFloat
    let delay: Double

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0.8

    var body: some View {
        HeartShape()
            .fill(tint.opacity(0.6))
            .frame(width: size, height: size)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    offsetY = -30
                    opacity = 0
                }
            }
    }
}

// MARK: - Hug Types

enum HugType: String, CaseIterable, Identifiable, Codable {
    case heart, puppy, bear, flower, star
    case sleepy, sweet, butterfly, rainbow, warm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heart: return "Heart Hug"
        case .puppy: return "Puppy Hug"
        case .bear: return "Bear Hug"
        case .flower: return "Flower Hug"
        case .star: return "Star Hug"
        case .sleepy: return "Sleepy Hug"
        case .sweet: return "Sweet Hug"
        case .butterfly: return "Butterfly Hug"
        case .rainbow: return "Rainbow Hug"
        case .warm: return "Warm Hug"
        }
    }

    var color: Color {
        switch self {
        case .heart: return Color(hex: "FF8FA3")
        case .puppy: return Color(hex: "C8A882")
        case .bear: return Color(hex: "8B6914")
        case .flower: return Color(hex: "E891B8")
        case .star: return Color(hex: "F5C842")
        case .sleepy: return Color(hex: "A89BD4")
        case .sweet: return Color(hex: "FF6B9D")
        case .butterfly: return Color(hex: "7DC4E0")
        case .rainbow: return Color(hex: "FF9A5C")
        case .warm: return Color(hex: "FF6B4A")
        }
    }

    var isLocked: Bool {
        switch self {
        case .sleepy, .sweet, .butterfly, .rainbow, .warm:
            return true
        default:
            return false
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if DEBUG
struct HugCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HugCharacterView(hugType: .heart, isHugging: false, size: 150)
            HugCharacterView(hugType: .bear, isHugging: true, size: 150)
        }
        .padding()
    }
}
#endif
