import SwiftUI

/// Renders a SceneObject as a bold-outline icon-style prop — no PNG assets,
/// no dark icon-box. Each known artwork key (`"art:bed"`, `"art:tv"`, etc.)
/// maps to a hand-drawn shape composition with black strokes and
/// white/cream fills plus characteristic accent details.
///
/// Design language (matches reference icons supplied by the user):
///   • Black stroke outline at ~lineWidth(width * 0.045) on the primary silhouette
///   • White / cream fills with one accent colour where iconic
///   • Distinguishing detail per prop (TV with remote, cup with falling water
///     drops, nurse-call with red button, etc.)
///   • Reads cleanly at any size — feels placeable like a SIMS prop
///
/// Props drawn: bed, pillow, tv, ivpole, cup, chair, window, clock, nurseCall.
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
            // Legacy data — render the SF symbol cleanly without a dark box
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

// MARK: - Style helpers

private enum Ink {
    static let stroke = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let lightFill = Color.white
    static let creamFill = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let pillowSeam = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let red    = Color(red: 0.86, green: 0.18, blue: 0.20)
    static let blue   = Color(red: 0.34, green: 0.62, blue: 0.92)
    static let sky    = Color(red: 0.74, green: 0.88, blue: 0.98)
    static let wood   = Color(red: 0.62, green: 0.46, blue: 0.32)
    static let cushion = Color(red: 0.88, green: 0.74, blue: 0.55)
}

/// Standard outline stroke width derived from the prop's smallest dimension.
private func strokeWidth(_ w: CGFloat, _ h: CGFloat) -> CGFloat {
    max(1.5, min(w, h) * 0.045)
}

// MARK: - Bed

private struct BedArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack {
            // Mattress + base outline (stylized hospital bed seen from the side)
            Path { p in
                let leftX: CGFloat = w * 0.05
                let rightX: CGFloat = w * 0.95
                let topY: CGFloat = h * 0.35
                let baseTopY: CGFloat = h * 0.62
                let baseBotY: CGFloat = h * 0.85

                // Mattress (rounded rect)
                p.move(to: CGPoint(x: leftX, y: topY))
                p.addLine(to: CGPoint(x: rightX, y: topY))
                p.addLine(to: CGPoint(x: rightX, y: baseTopY))
                p.addLine(to: CGPoint(x: leftX, y: baseTopY))
                p.closeSubpath()

                // Base / frame
                p.move(to: CGPoint(x: leftX + w * 0.05, y: baseTopY))
                p.addLine(to: CGPoint(x: rightX - w * 0.05, y: baseTopY))
                p.addLine(to: CGPoint(x: rightX - w * 0.05, y: baseBotY))
                p.addLine(to: CGPoint(x: leftX + w * 0.05, y: baseBotY))
                p.closeSubpath()
            }
            .fill(Ink.lightFill)

            Path { p in
                let leftX: CGFloat = w * 0.05
                let rightX: CGFloat = w * 0.95
                let topY: CGFloat = h * 0.35
                let baseTopY: CGFloat = h * 0.62
                let baseBotY: CGFloat = h * 0.85
                p.addRoundedRect(
                    in: CGRect(x: leftX, y: topY,
                               width: rightX - leftX, height: baseTopY - topY),
                    cornerSize: CGSize(width: lw, height: lw)
                )
                p.addRect(CGRect(x: leftX + w * 0.05, y: baseTopY,
                                 width: (rightX - leftX) - w * 0.10,
                                 height: baseBotY - baseTopY))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Headboard (taller box on the left, like a hospital bed)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.02, y: h * 0.10,
                               width: w * 0.10, height: h * 0.55),
                    cornerSize: CGSize(width: lw, height: lw)
                )
            }
            .fill(Ink.lightFill)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.02, y: h * 0.10,
                               width: w * 0.10, height: h * 0.55),
                    cornerSize: CGSize(width: lw, height: lw)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Pillow at the head end of the mattress
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.13, y: h * 0.40,
                               width: w * 0.20, height: h * 0.16),
                    cornerSize: CGSize(width: w * 0.04, height: w * 0.04)
                )
            }
            .fill(Ink.lightFill)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.13, y: h * 0.40,
                               width: w * 0.20, height: h * 0.16),
                    cornerSize: CGSize(width: w * 0.04, height: w * 0.04)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 0.7, lineJoin: .round))

            // Sheet fold line on mattress
            Path { p in
                p.move(to: CGPoint(x: w * 0.40, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.50))
            }
            .stroke(Ink.stroke.opacity(0.55), style: StrokeStyle(lineWidth: lw * 0.55, lineCap: .round))

            // Foot board (slim vertical at the right edge)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.92, y: h * 0.30,
                               width: w * 0.05, height: h * 0.32),
                    cornerSize: CGSize(width: lw * 0.5, height: lw * 0.5)
                )
            }
            .fill(Ink.lightFill)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.92, y: h * 0.30,
                               width: w * 0.05, height: h * 0.32),
                    cornerSize: CGSize(width: lw * 0.5, height: lw * 0.5)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Wheels (two black circles at the bottom)
            Circle()
                .fill(Ink.stroke)
                .frame(width: w * 0.06, height: w * 0.06)
                .position(x: w * 0.20, y: h * 0.90)
            Circle()
                .fill(Ink.stroke)
                .frame(width: w * 0.06, height: w * 0.06)
                .position(x: w * 0.80, y: h * 0.90)
        }
    }
}

// MARK: - Pillow (matches reference: soft outline + seam)

private struct PillowArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack {
            // Soft pillow shape (rounded rectangle, slightly squashed)
            RoundedRectangle(cornerRadius: min(w, h) * 0.32)
                .fill(Ink.lightFill)

            RoundedRectangle(cornerRadius: min(w, h) * 0.32)
                .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Seam line down the centre (curved suggestion of softness)
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.50, y: h * 0.80),
                    control: CGPoint(x: w * 0.55, y: h * 0.50)
                )
            }
            .stroke(Ink.pillowSeam, style: StrokeStyle(lineWidth: lw * 0.55, lineCap: .round))

            // Tiny crease at the corner
            Path { p in
                p.move(to: CGPoint(x: w * 0.18, y: h * 0.22))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.30, y: h * 0.30),
                    control: CGPoint(x: w * 0.22, y: h * 0.18)
                )
            }
            .stroke(Ink.pillowSeam, style: StrokeStyle(lineWidth: lw * 0.45, lineCap: .round))
        }
    }
}

// MARK: - TV (with small remote control + arrow accent)

private struct TVArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack(alignment: .topLeading) {
            // TV bezel
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.08, y: h * 0.05,
                               width: w * 0.84, height: h * 0.62),
                    cornerSize: CGSize(width: lw * 1.5, height: lw * 1.5)
                )
            }
            .fill(Ink.stroke)

            // Inner screen — solid black with subtle highlight
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.13, y: h * 0.10,
                               width: w * 0.74, height: h * 0.50),
                    cornerSize: CGSize(width: lw, height: lw)
                )
            }
            .fill(Color(red: 0.06, green: 0.08, blue: 0.12))

            // "TV" text inside the screen
            Text("TV")
                .font(.system(size: min(w, h) * 0.28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: w * 0.74, height: h * 0.50)
                .offset(x: w * 0.13, y: h * 0.10)

            // Stand (small triangular foot under the bezel)
            Path { p in
                p.move(to: CGPoint(x: w * 0.42, y: h * 0.67))
                p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.67))
                p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.74))
                p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.74))
                p.closeSubpath()
            }
            .fill(Ink.stroke)

            // Stand base line
            Path { p in
                p.move(to: CGPoint(x: w * 0.30, y: h * 0.74))
                p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.74))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))

            // Remote control — small rounded pill in lower-right
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.62, y: h * 0.78,
                               width: w * 0.32, height: h * 0.20),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .fill(Ink.lightFill)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.62, y: h * 0.78,
                               width: w * 0.32, height: h * 0.20),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 0.7, lineJoin: .round))

            // Arrow / play triangle on the remote
            Path { p in
                let cx = w * 0.74
                let cy = h * 0.88
                p.move(to: CGPoint(x: cx - w * 0.03, y: cy - h * 0.04))
                p.addLine(to: CGPoint(x: cx + w * 0.03, y: cy))
                p.addLine(to: CGPoint(x: cx - w * 0.03, y: cy + h * 0.04))
                p.closeSubpath()
            }
            .fill(Ink.stroke)

            // Round button on the remote
            Circle()
                .fill(Ink.stroke)
                .frame(width: w * 0.04, height: w * 0.04)
                .position(x: w * 0.86, y: h * 0.88)
        }
    }
}

// MARK: - IV pole (clear bag with red label, hooked to a stand)

private struct IVPoleArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack(alignment: .top) {
            // Hook at top
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.02))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.50, y: h * 0.10),
                    control: CGPoint(x: w * 0.20, y: h * 0.04)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))

            // IV bag (rounded rect with flat top)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.18, y: h * 0.10,
                               width: w * 0.64, height: h * 0.30),
                    cornerSize: CGSize(width: w * 0.10, height: w * 0.10)
                )
            }
            .fill(Ink.lightFill)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.18, y: h * 0.10,
                               width: w * 0.64, height: h * 0.30),
                    cornerSize: CGSize(width: w * 0.10, height: w * 0.10)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Red label band on the bag
            Path { p in
                p.addRect(CGRect(x: w * 0.18, y: h * 0.20,
                                 width: w * 0.64, height: h * 0.06))
            }
            .fill(Ink.red)

            // Pole — vertical line below the bag
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.40))
                p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.92))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))

            // Tubing dropping down from the bag
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: h * 0.40))
                p.addCurve(
                    to: CGPoint(x: w * 0.78, y: h * 0.92),
                    control1: CGPoint(x: w * 0.50, y: h * 0.62),
                    control2: CGPoint(x: w * 0.86, y: h * 0.78)
                )
            }
            .stroke(Ink.blue.opacity(0.85), style: StrokeStyle(lineWidth: lw * 0.75, lineCap: .round))

            // Wheel base — short horizontal stroke at the bottom
            Path { p in
                p.move(to: CGPoint(x: w * 0.32, y: h * 0.94))
                p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.94))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))

            // Two wheels
            Circle()
                .fill(Ink.stroke)
                .frame(width: w * 0.10, height: w * 0.10)
                .position(x: w * 0.34, y: h * 0.96)
            Circle()
                .fill(Ink.stroke)
                .frame(width: w * 0.10, height: w * 0.10)
                .position(x: w * 0.66, y: h * 0.96)
        }
    }
}

// MARK: - Cup (matches reference: outlined glass with falling drops)

private struct CupArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack(alignment: .top) {
            // Two falling water drops above the cup
            drop(at: CGPoint(x: w * 0.36, y: h * 0.10), size: w * 0.10)
            drop(at: CGPoint(x: w * 0.62, y: h * 0.05), size: w * 0.12)

            // Glass body (slightly tapered)
            Path { p in
                let topL = CGPoint(x: w * 0.18, y: h * 0.38)
                let topR = CGPoint(x: w * 0.82, y: h * 0.38)
                let botR = CGPoint(x: w * 0.74, y: h * 0.94)
                let botL = CGPoint(x: w * 0.26, y: h * 0.94)

                p.move(to: topL)
                p.addLine(to: topR)
                p.addLine(to: botR)
                p.addQuadCurve(to: botL, control: CGPoint(x: w * 0.50, y: h * 1.02))
                p.closeSubpath()
            }
            .fill(Ink.lightFill)

            Path { p in
                let topL = CGPoint(x: w * 0.18, y: h * 0.38)
                let topR = CGPoint(x: w * 0.82, y: h * 0.38)
                let botR = CGPoint(x: w * 0.74, y: h * 0.94)
                let botL = CGPoint(x: w * 0.26, y: h * 0.94)

                p.move(to: topL)
                p.addLine(to: topR)
                p.addLine(to: botR)
                p.addQuadCurve(to: botL, control: CGPoint(x: w * 0.50, y: h * 1.02))
                p.closeSubpath()
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Wavy water line inside the glass
            Path { p in
                let y = h * 0.62
                let xL = w * 0.21
                let xR = w * 0.79
                p.move(to: CGPoint(x: xL, y: y))
                p.addCurve(
                    to: CGPoint(x: xR, y: y),
                    control1: CGPoint(x: w * 0.40, y: y - h * 0.04),
                    control2: CGPoint(x: w * 0.60, y: y + h * 0.04)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 0.85, lineCap: .round))
        }
    }

    /// A single black-outlined teardrop water drop centred at `centre`.
    private func drop(at centre: CGPoint, size: CGFloat) -> some View {
        let lw = strokeWidth(w, h) * 0.7
        return Path { p in
            let s = size
            let top = CGPoint(x: centre.x, y: centre.y - s * 0.5)
            let right = CGPoint(x: centre.x + s * 0.40, y: centre.y + s * 0.20)
            let bottom = CGPoint(x: centre.x, y: centre.y + s * 0.55)
            let left = CGPoint(x: centre.x - s * 0.40, y: centre.y + s * 0.20)

            p.move(to: top)
            p.addQuadCurve(to: right, control: CGPoint(x: centre.x + s * 0.45, y: centre.y - s * 0.20))
            p.addQuadCurve(to: bottom, control: CGPoint(x: centre.x + s * 0.45, y: centre.y + s * 0.50))
            p.addQuadCurve(to: left, control: CGPoint(x: centre.x - s * 0.45, y: centre.y + s * 0.50))
            p.addQuadCurve(to: top, control: CGPoint(x: centre.x - s * 0.45, y: centre.y - s * 0.20))
            p.closeSubpath()
        }
        .fill(Ink.lightFill)
        .overlay {
            Path { p in
                let s = size
                let top = CGPoint(x: centre.x, y: centre.y - s * 0.5)
                let right = CGPoint(x: centre.x + s * 0.40, y: centre.y + s * 0.20)
                let bottom = CGPoint(x: centre.x, y: centre.y + s * 0.55)
                let left = CGPoint(x: centre.x - s * 0.40, y: centre.y + s * 0.20)

                p.move(to: top)
                p.addQuadCurve(to: right, control: CGPoint(x: centre.x + s * 0.45, y: centre.y - s * 0.20))
                p.addQuadCurve(to: bottom, control: CGPoint(x: centre.x + s * 0.45, y: centre.y + s * 0.50))
                p.addQuadCurve(to: left, control: CGPoint(x: centre.x - s * 0.45, y: centre.y + s * 0.50))
                p.addQuadCurve(to: top, control: CGPoint(x: centre.x - s * 0.45, y: centre.y - s * 0.20))
                p.closeSubpath()
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))
        }
    }
}

// MARK: - Chair (family armchair silhouette)

private struct ChairArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack {
            // Backrest
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.12, y: h * 0.05,
                               width: w * 0.76, height: h * 0.55),
                    cornerSize: CGSize(width: w * 0.10, height: w * 0.10)
                )
            }
            .fill(Ink.cushion)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.12, y: h * 0.05,
                               width: w * 0.76, height: h * 0.55),
                    cornerSize: CGSize(width: w * 0.10, height: w * 0.10)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Seat cushion
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.04, y: h * 0.50,
                               width: w * 0.92, height: h * 0.30),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .fill(Ink.cushion)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.04, y: h * 0.50,
                               width: w * 0.92, height: h * 0.30),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Left arm
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.00, y: h * 0.32,
                               width: w * 0.16, height: h * 0.50),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .fill(Ink.cushion)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.00, y: h * 0.32,
                               width: w * 0.16, height: h * 0.50),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Right arm
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.84, y: h * 0.32,
                               width: w * 0.16, height: h * 0.50),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .fill(Ink.cushion)
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.84, y: h * 0.32,
                               width: w * 0.16, height: h * 0.50),
                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Two legs (short stubs)
            Path { p in
                p.move(to: CGPoint(x: w * 0.18, y: h * 0.80))
                p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.94))
                p.move(to: CGPoint(x: w * 0.82, y: h * 0.80))
                p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.94))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))
        }
    }
}

// MARK: - Window (frame + sky panes + curtains)

private struct WindowArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack {
            // Frame
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.10, y: h * 0.06,
                               width: w * 0.80, height: h * 0.84),
                    cornerSize: CGSize(width: lw, height: lw)
                )
            }
            .fill(Ink.lightFill)

            // Sky inside
            Path { p in
                p.addRect(CGRect(x: w * 0.16, y: h * 0.12,
                                 width: w * 0.68, height: h * 0.72))
            }
            .fill(Ink.sky)

            // Cross mullions
            Path { p in
                p.addRect(CGRect(x: w * 0.16, y: h * 0.46,
                                 width: w * 0.68, height: lw * 1.2))
                p.addRect(CGRect(x: w * 0.48, y: h * 0.12,
                                 width: lw * 1.2, height: h * 0.72))
            }
            .fill(Ink.stroke)

            // Cloud
            Group {
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.12, height: w * 0.12)
                    .position(x: w * 0.32, y: h * 0.28)
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.16, height: w * 0.16)
                    .position(x: w * 0.40, y: h * 0.30)
            }

            // Outer frame stroke
            Path { p in
                p.addRoundedRect(
                    in: CGRect(x: w * 0.10, y: h * 0.06,
                               width: w * 0.80, height: h * 0.84),
                    cornerSize: CGSize(width: lw, height: lw)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineJoin: .round))

            // Inner pane stroke
            Path { p in
                p.addRect(CGRect(x: w * 0.16, y: h * 0.12,
                                 width: w * 0.68, height: h * 0.72))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 0.7, lineJoin: .round))

            // Curtain rod across the top
            Path { p in
                p.move(to: CGPoint(x: w * 0.04, y: h * 0.06))
                p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.06))
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))

            // Tiny curtain ties on left and right
            curtainTie(x: w * 0.10)
            curtainTie(x: w * 0.90)
        }
    }

    private func curtainTie(x: CGFloat) -> some View {
        let lw = strokeWidth(w, h) * 0.7
        return Path { p in
            p.move(to: CGPoint(x: x - w * 0.03, y: h * 0.06))
            p.addQuadCurve(
                to: CGPoint(x: x + w * 0.03, y: h * 0.30),
                control: CGPoint(x: x - w * 0.06, y: h * 0.18)
            )
        }
        .stroke(Ink.red.opacity(0.85), style: StrokeStyle(lineWidth: lw, lineCap: .round))
    }
}

// MARK: - Clock (analog, bold outline)

private struct ClockArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)
        let r = min(w, h) * 0.45

        ZStack {
            Circle()
                .fill(Ink.lightFill)
                .frame(width: r * 2, height: r * 2)

            Circle()
                .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw))
                .frame(width: r * 2, height: r * 2)

            // 12 / 3 / 6 / 9 ticks
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Ink.stroke)
                    .frame(width: lw * 0.8, height: r * 0.18)
                    .offset(y: -r * 0.85)
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            // Hour hand (pointing to 10)
            Capsule()
                .fill(Ink.stroke)
                .frame(width: lw * 1.2, height: r * 0.55)
                .offset(y: -r * 0.20)
                .rotationEffect(.degrees(-60))

            // Minute hand (pointing to 2)
            Capsule()
                .fill(Ink.stroke)
                .frame(width: lw * 0.9, height: r * 0.78)
                .offset(y: -r * 0.32)
                .rotationEffect(.degrees(60))

            // Centre cap
            Circle()
                .fill(Ink.red)
                .frame(width: r * 0.20, height: r * 0.20)
        }
    }
}

// MARK: - Nurse call button (round red button on a cord, with a white plus)

private struct NurseCallArt: View {
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        let lw = strokeWidth(w, h)

        ZStack {
            // Cord coming down from the top
            Path { p in
                p.move(to: CGPoint(x: w * 0.50, y: 0))
                p.addCurve(
                    to: CGPoint(x: w * 0.50, y: h * 0.45),
                    control1: CGPoint(x: w * 0.30, y: h * 0.18),
                    control2: CGPoint(x: w * 0.70, y: h * 0.32)
                )
            }
            .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw * 0.9, lineCap: .round))

            // Button body
            Circle()
                .fill(Ink.red)
                .frame(width: w * 0.86, height: w * 0.86)
                .offset(y: h * 0.20)

            Circle()
                .stroke(Ink.stroke, style: StrokeStyle(lineWidth: lw))
                .frame(width: w * 0.86, height: w * 0.86)
                .offset(y: h * 0.20)

            // White plus icon
            ZStack {
                Capsule()
                    .fill(Color.white)
                    .frame(width: w * 0.46, height: w * 0.14)
                Capsule()
                    .fill(Color.white)
                    .frame(width: w * 0.14, height: w * 0.46)
            }
            .offset(y: h * 0.20)
        }
    }
}
