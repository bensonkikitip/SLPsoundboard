import SwiftUI

/// Renders a SceneObject as a semi-realistic SwiftUI prop — no PNG assets, no
/// dark icon-box. Each known artwork key (`"art:bed"`, `"art:tv"`, etc.) maps
/// to a hand-drawn shape composition. Unknown keys fall back to the SF symbol
/// (legacy `"sfsymbol:..."` data) or a neutral placeholder.
///
/// Props drawn:
///   bed, pillow, tv, ivpole, cup, toilet, chair, window, clock, nurseCall
struct SceneObjectArtworkView: View {

    let object: SceneObject
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            switch object.artworkKey {
            case "bed":       BedArt(w: width, h: height)
            case "pillow":    PillowArt(w: width, h: height)
            case "tv":        TVArt(w: width, h: height)
            case "ivpole":    IVPoleArt(w: width, h: height)
            case "cup":       CupArt(w: width, h: height)
            case "toilet":    ToiletArt(w: width, h: height)
            case "chair":     ChairArt(w: width, h: height)
            case "window":    WindowArt(w: width, h: height)
            case "clock":     ClockArt(w: width, h: height)
            case "nurseCall": NurseCallArt(w: width, h: height)
            default:          fallbackArt
            }
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private var fallbackArt: some View {
        if let sfName = object.systemImageName {
            // Legacy data — render the SF symbol cleanly without the dark box
            Image(systemName: sfName)
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .padding(width * 0.10)
                .shadow(color: .black.opacity(0.20), radius: 2, y: 1)
        } else {
            // Unknown — soft neutral placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.25))
                .overlay {
                    Image(systemName: "shippingbox")
                        .font(.system(size: min(width, height) * 0.35))
                        .foregroundStyle(.secondary)
                }
        }
    }
}

// MARK: - Bed (hospital bed: mattress + headboard + pillow + side rails)

private struct BedArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Headboard (left edge)
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [Color(red: 0.38, green: 0.50, blue: 0.62),
                             Color(red: 0.28, green: 0.40, blue: 0.52)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.10, height: h * 0.95)
                .offset(x: 0, y: 0)

            // Mattress
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    colors: [Color(red: 0.96, green: 0.97, blue: 0.99),
                             Color(red: 0.86, green: 0.89, blue: 0.93)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.85, height: h * 0.70)
                .offset(x: w * 0.10, y: h * 0.18)

            // Bedsheet fold lines
            ForEach([0.40, 0.60], id: \.self) { fraction in
                Path { p in
                    p.move(to: CGPoint(x: w * 0.12, y: h * fraction))
                    p.addLine(to: CGPoint(x: w * 0.92, y: h * fraction))
                }
                .stroke(Color(red: 0.78, green: 0.84, blue: 0.90), lineWidth: 1)
            }

            // Side rail (top of bed)
            Capsule()
                .fill(Color(red: 0.55, green: 0.62, blue: 0.70))
                .frame(width: w * 0.78, height: h * 0.04)
                .offset(x: w * 0.13, y: h * 0.20)

            // Side rail (bottom of bed)
            Capsule()
                .fill(Color(red: 0.55, green: 0.62, blue: 0.70))
                .frame(width: w * 0.78, height: h * 0.04)
                .offset(x: w * 0.13, y: h * 0.84)

            // Foot board (right edge)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.45, green: 0.55, blue: 0.65))
                .frame(width: w * 0.04, height: h * 0.62)
                .offset(x: w * 0.95, y: h * 0.22)
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
    }
}

// MARK: - Pillow

private struct PillowArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: min(w, h) * 0.32)
                .fill(LinearGradient(
                    colors: [Color.white,
                             Color(red: 0.92, green: 0.93, blue: 0.95)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: .black.opacity(0.20), radius: 3, y: 2)

            // Subtle indent line down the centre
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.80))
            }
            .stroke(Color(red: 0.85, green: 0.86, blue: 0.88), lineWidth: 1)
        }
    }
}

// MARK: - TV (flat-screen + small wall mount + power LED)

private struct TVArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // Bezel
            RoundedRectangle(cornerRadius: w * 0.04)
                .fill(LinearGradient(
                    colors: [Color(red: 0.10, green: 0.10, blue: 0.12),
                             Color(red: 0.04, green: 0.04, blue: 0.06)],
                    startPoint: .top, endPoint: .bottom
                ))

            // Screen
            RoundedRectangle(cornerRadius: w * 0.02)
                .fill(LinearGradient(
                    colors: [Color(red: 0.10, green: 0.20, blue: 0.36),
                             Color(red: 0.04, green: 0.08, blue: 0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: w * 0.88, height: h * 0.72)
                .offset(y: h * 0.06)

            // Soft screen reflection
            RoundedRectangle(cornerRadius: w * 0.02)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.18), .clear],
                    startPoint: .topLeading, endPoint: .center
                ))
                .frame(width: w * 0.88, height: h * 0.72)
                .offset(y: h * 0.06)

            // Wall mount stem (below the bezel)
            Rectangle()
                .fill(Color(red: 0.40, green: 0.40, blue: 0.42))
                .frame(width: w * 0.06, height: h * 0.12)
                .offset(y: h * 0.86)

            // Power LED dot
            Circle()
                .fill(Color.green.opacity(0.85))
                .frame(width: w * 0.02, height: w * 0.02)
                .offset(x: w * 0.42, y: h * 0.78)
        }
        .shadow(color: .black.opacity(0.30), radius: 5, y: 3)
    }
}

// MARK: - IV pole (vertical pole + hanging bag with red label)

private struct IVPoleArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // Pole — thin grey vertical
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.78, green: 0.80, blue: 0.84),
                             Color(red: 0.56, green: 0.58, blue: 0.62)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: w * 0.16, height: h * 0.92)
                .offset(y: h * 0.08)

            // Top hook
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: 0))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.06))
                p.addArc(
                    center: CGPoint(x: w * 0.30, y: h * 0.06),
                    radius: w * 0.20,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: true
                )
            }
            .stroke(Color(red: 0.50, green: 0.52, blue: 0.56), lineWidth: max(1.5, w * 0.06))

            // IV bag
            RoundedRectangle(cornerRadius: w * 0.10)
                .fill(LinearGradient(
                    colors: [Color(red: 0.95, green: 0.97, blue: 1.00).opacity(0.90),
                             Color(red: 0.80, green: 0.88, blue: 0.96).opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.80, height: h * 0.30)
                .offset(y: h * 0.16)

            // Red label band on the IV bag
            Rectangle()
                .fill(Color(red: 0.86, green: 0.18, blue: 0.18))
                .frame(width: w * 0.80, height: h * 0.04)
                .offset(y: h * 0.30)

            // Tubing dangling down
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
                p.addCurve(
                    to: CGPoint(x: w * 0.62, y: h * 0.95),
                    control1: CGPoint(x: w * 0.50, y: h * 0.65),
                    control2: CGPoint(x: w * 0.74, y: h * 0.80)
                )
            }
            .stroke(Color(red: 0.80, green: 0.85, blue: 0.92), lineWidth: max(1, w * 0.04))
        }
    }
}

// MARK: - Cup (clear glass on a small saucer with water)

private struct CupArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Saucer
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(red: 0.92, green: 0.93, blue: 0.95),
                             Color(red: 0.78, green: 0.80, blue: 0.82)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.95, height: h * 0.18)
                .offset(y: -h * 0.04)

            // Glass body
            Path { p in
                let xL = w * 0.20
                let xR = w * 0.80
                p.move(to: CGPoint(x: xL, y: h * 0.20))
                p.addLine(to: CGPoint(x: xL + w * 0.04, y: h * 0.86))
                p.addQuadCurve(
                    to: CGPoint(x: xR - w * 0.04, y: h * 0.86),
                    control: CGPoint(x: w * 0.50, y: h * 0.92)
                )
                p.addLine(to: CGPoint(x: xR, y: h * 0.20))
                p.closeSubpath()
            }
            .fill(LinearGradient(
                colors: [Color(red: 0.85, green: 0.93, blue: 1.00).opacity(0.55),
                         Color(red: 0.60, green: 0.78, blue: 0.95).opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            ))

            // Water level
            Path { p in
                let xL = w * 0.24
                let xR = w * 0.76
                p.move(to: CGPoint(x: xL, y: h * 0.46))
                p.addLine(to: CGPoint(x: xR, y: h * 0.46))
                p.addLine(to: CGPoint(x: xR - w * 0.03, y: h * 0.84))
                p.addQuadCurve(
                    to: CGPoint(x: xL + w * 0.03, y: h * 0.84),
                    control: CGPoint(x: w * 0.50, y: h * 0.90)
                )
                p.closeSubpath()
            }
            .fill(Color(red: 0.42, green: 0.66, blue: 0.92).opacity(0.65))

            // Glass rim (ellipse top)
            Ellipse()
                .stroke(Color(red: 0.55, green: 0.72, blue: 0.90), lineWidth: max(1, w * 0.04))
                .frame(width: w * 0.60, height: h * 0.10)
                .offset(y: -h * 0.62)

            // Highlight
            Path { p in
                p.move(to: CGPoint(x: w * 0.30, y: h * 0.30))
                p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.78))
            }
            .stroke(Color.white.opacity(0.50), lineWidth: max(1, w * 0.03))
        }
    }
}

// MARK: - Toilet (tank + bowl)

private struct ToiletArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // Tank (back, top half)
            RoundedRectangle(cornerRadius: w * 0.04)
                .fill(LinearGradient(
                    colors: [Color.white,
                             Color(red: 0.88, green: 0.90, blue: 0.92)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.62, height: h * 0.38)
                .offset(x: w * 0.04, y: 0)

            // Flush handle
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0.65, green: 0.67, blue: 0.70))
                .frame(width: w * 0.10, height: h * 0.03)
                .offset(x: w * 0.10, y: h * 0.10)

            // Lid hinge between tank and bowl
            Rectangle()
                .fill(Color(red: 0.78, green: 0.80, blue: 0.82))
                .frame(width: w * 0.66, height: h * 0.03)
                .offset(x: w * 0.02, y: h * 0.36)

            // Bowl — front, oval-ish
            Path { p in
                let topY: CGFloat = h * 0.42
                let botY: CGFloat = h * 0.96
                p.move(to: CGPoint(x: w * 0.06, y: topY))
                p.addLine(to: CGPoint(x: w * 0.94, y: topY))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.50, y: botY),
                    control: CGPoint(x: w * 1.05, y: h * 0.90)
                )
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.06, y: topY),
                    control: CGPoint(x: w * -0.05, y: h * 0.90)
                )
            }
            .fill(LinearGradient(
                colors: [Color.white,
                         Color(red: 0.86, green: 0.88, blue: 0.90)],
                startPoint: .top, endPoint: .bottom
            ))

            // Bowl interior (water)
            Ellipse()
                .fill(Color(red: 0.62, green: 0.78, blue: 0.92).opacity(0.50))
                .frame(width: w * 0.58, height: h * 0.18)
                .offset(x: w * 0.06, y: h * 0.55)

            // Seat outline
            Ellipse()
                .stroke(Color(red: 0.70, green: 0.72, blue: 0.74), lineWidth: max(1, w * 0.04))
                .frame(width: w * 0.78, height: h * 0.40)
                .offset(x: w * -0.04, y: h * 0.42)
        }
        .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
    }
}

// MARK: - Chair (family armchair silhouette)

private struct ChairArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backrest
            RoundedRectangle(cornerRadius: w * 0.10)
                .fill(LinearGradient(
                    colors: [Color(red: 0.65, green: 0.50, blue: 0.40),
                             Color(red: 0.50, green: 0.36, blue: 0.28)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.78, height: h * 0.68)
                .offset(x: w * 0.11, y: -h * 0.32)

            // Seat cushion
            RoundedRectangle(cornerRadius: w * 0.08)
                .fill(Color(red: 0.72, green: 0.58, blue: 0.46))
                .frame(width: w * 0.92, height: h * 0.30)
                .offset(y: -h * 0.10)

            // Left arm
            RoundedRectangle(cornerRadius: w * 0.06)
                .fill(Color(red: 0.55, green: 0.42, blue: 0.32))
                .frame(width: w * 0.16, height: h * 0.46)
                .offset(x: -w * 0.38, y: -h * 0.16)

            // Right arm
            RoundedRectangle(cornerRadius: w * 0.06)
                .fill(Color(red: 0.55, green: 0.42, blue: 0.32))
                .frame(width: w * 0.16, height: h * 0.46)
                .offset(x: w * 0.38, y: -h * 0.16)

            // Legs (subtle dark base)
            Rectangle()
                .fill(Color(red: 0.30, green: 0.22, blue: 0.16))
                .frame(width: w * 0.92, height: h * 0.05)
        }
        .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
    }
}

// MARK: - Window (frame + curtains + sky)

private struct WindowArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack {
            // Window frame
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.96))

            // Sky pane
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.62, green: 0.82, blue: 0.96),
                             Color(red: 0.86, green: 0.94, blue: 1.00)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: w * 0.86, height: h * 0.86)

            // Cross mullions
            Rectangle()
                .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                .frame(width: w * 0.86, height: max(1, h * 0.04))
            Rectangle()
                .fill(Color(red: 0.95, green: 0.95, blue: 0.96))
                .frame(width: max(1, w * 0.04), height: h * 0.86)

            // Subtle cloud
            Ellipse()
                .fill(Color.white.opacity(0.85))
                .frame(width: w * 0.30, height: h * 0.10)
                .offset(x: -w * 0.12, y: -h * 0.20)

            // Outer frame
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(red: 0.78, green: 0.78, blue: 0.80), lineWidth: max(1, min(w, h) * 0.04))

            // Curtain panels on the outer edges
            curtainPanel
                .frame(maxWidth: .infinity, alignment: .leading)
            curtainPanel
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }

    private var curtainPanel: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.60, green: 0.30, blue: 0.30), location: 0.0),
                .init(color: Color(red: 0.78, green: 0.45, blue: 0.45), location: 0.5),
                .init(color: Color(red: 0.55, green: 0.28, blue: 0.28), location: 1.0),
            ],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: w * 0.14)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Clock (analog wall clock)

private struct ClockArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack {
            // Clock face
            Circle()
                .fill(LinearGradient(
                    colors: [Color.white,
                             Color(red: 0.92, green: 0.92, blue: 0.94)],
                    startPoint: .top, endPoint: .bottom
                ))
            // Bezel
            Circle()
                .stroke(Color(red: 0.30, green: 0.32, blue: 0.34), lineWidth: max(1, min(w, h) * 0.06))

            // Hour ticks (12, 3, 6, 9)
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.32, blue: 0.34))
                    .frame(width: max(1, min(w, h) * 0.025),
                           height: i % 3 == 0 ? min(w, h) * 0.10 : min(w, h) * 0.05)
                    .offset(y: -min(w, h) * 0.40)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Hour hand (pointing to 10)
            Capsule()
                .fill(Color(red: 0.10, green: 0.12, blue: 0.14))
                .frame(width: max(1, min(w, h) * 0.04), height: min(w, h) * 0.30)
                .offset(y: -min(w, h) * 0.12)
                .rotationEffect(.degrees(-60))

            // Minute hand (pointing to 2)
            Capsule()
                .fill(Color(red: 0.10, green: 0.12, blue: 0.14))
                .frame(width: max(1, min(w, h) * 0.03), height: min(w, h) * 0.40)
                .offset(y: -min(w, h) * 0.18)
                .rotationEffect(.degrees(60))

            // Centre cap
            Circle()
                .fill(Color(red: 0.78, green: 0.20, blue: 0.20))
                .frame(width: min(w, h) * 0.10, height: min(w, h) * 0.10)
        }
        .shadow(color: .black.opacity(0.20), radius: 3, y: 2)
    }
}

// MARK: - Nurse call button (round red button on a thin cord)

private struct NurseCallArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            // Cord (curved) — drawn first, behind the button
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: 0))
                p.addCurve(
                    to: CGPoint(x: w * 0.50, y: h * 0.50),
                    control1: CGPoint(x: w * 0.30, y: h * 0.18),
                    control2: CGPoint(x: w * 0.70, y: h * 0.34)
                )
            }
            .stroke(Color(red: 0.85, green: 0.85, blue: 0.88), lineWidth: max(1, min(w, h) * 0.06))

            // Button body
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.96, green: 0.30, blue: 0.30),
                             Color(red: 0.70, green: 0.10, blue: 0.10)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: min(w, h) * 0.80
                ))
                .frame(width: w * 0.80, height: w * 0.80)
                .offset(y: h * 0.45)

            // Inner highlight
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: max(1, w * 0.04))
                .frame(width: w * 0.55, height: w * 0.55)
                .offset(y: h * 0.45 + w * 0.12)

            // White cross icon
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: w * 0.32, height: w * 0.10)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: w * 0.10, height: w * 0.32)
            }
            .offset(y: h * 0.45 + w * 0.40)
        }
        .shadow(color: .black.opacity(0.30), radius: 3, y: 2)
    }
}
