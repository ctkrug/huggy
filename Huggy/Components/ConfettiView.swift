import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    private let colors: [Color] = [
        Color(hex: "FF8FA3"),
        Color(hex: "FF6B6B"),
        Color(hex: "F5C842"),
        Color(hex: "7DC4E0"),
        Color(hex: "E891B8"),
        Color(hex: "FF9A5C"),
        Color(hex: "A89BD4")
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x * size.width,
                        y: animating ? particle.endY * size.height : particle.startY * size.height,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(
                        RoundedRectangle(cornerRadius: particle.size * 0.3).path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
            .onAppear {
                particles = (0..<60).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...1),
                        startY: CGFloat.random(in: -0.3...(-0.05)),
                        endY: CGFloat.random(in: 1.0...1.4),
                        size: CGFloat.random(in: 4...10),
                        color: colors.randomElement() ?? .pink
                    )
                }
                withAnimation(.easeIn(duration: 2.5)) {
                    animating = true
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct ConfettiParticle {
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let color: Color
}
