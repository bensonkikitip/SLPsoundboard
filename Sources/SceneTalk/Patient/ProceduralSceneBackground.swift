import SwiftUI

/// Procedurally-drawn SwiftUI backgrounds for stock scenes.
///
/// Stored in `SceneTalkScene.backgroundAssetName` using the prefix `"procedural:"`.
/// Example: `"procedural:hospital"`, `"procedural:kitchen"`, `"procedural:living"`.
///
/// These backgrounds display immediately without any photo assets and give each
/// scene a distinct visual identity. Family replaces them with real photos over time.
enum ProceduralBackground {

    enum Style: String, CaseIterable {
        case hospital = "hospital"
        case kitchen  = "kitchen"
        case living   = "living"
    }

    /// Returns the Style for a backgroundAssetName, or nil if it's not procedural.
    static func style(from assetName: String?) -> Style? {
        guard let name = assetName, name.hasPrefix("procedural:") else { return nil }
        return Style(rawValue: String(name.dropFirst("procedural:".count)))
    }
}

// MARK: - SwiftUI View

struct ProceduralSceneBackgroundView: View {
    let style: ProceduralBackground.Style

    var body: some View {
        switch style {
        case .hospital: hospitalBackground
        case .kitchen:  kitchenBackground
        case .living:   livingRoomBackground
        }
    }

    // MARK: - Hospital Room
    // Cool clinical palette: soft blue-white walls, beige tile floor with grout
    // grid, baseboard, and faint curtain rod hint along the upper edge.
    // The bed and other props are real SceneObjects placed on top — not painted
    // into the background.

    private var hospitalBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.65
            let baseboardThickness: CGFloat = max(2, h * 0.012)

            ZStack {
                // ── Wall gradient (ceiling → wall)
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.96, green: 0.97, blue: 0.99), location: 0.0),
                        .init(color: Color(red: 0.87, green: 0.92, blue: 0.96), location: 0.65),
                        .init(color: Color(red: 0.82, green: 0.87, blue: 0.91), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // ── Soft warm window glow (upper-right wall)
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.white.opacity(0.0),
                    ],
                    center: UnitPoint(x: 0.82, y: 0.12),
                    startRadius: 0,
                    endRadius: w * 0.35
                )

                // ── Curtain rod hint along the upper edge
                Path { p in
                    p.move(to: CGPoint(x: w * 0.03, y: h * 0.04))
                    p.addLine(to: CGPoint(x: w * 0.97, y: h * 0.04))
                }
                .stroke(Color(red: 0.62, green: 0.66, blue: 0.72).opacity(0.55),
                        style: StrokeStyle(lineWidth: max(1, h * 0.005), lineCap: .round))

                // Curtain rod end-caps
                Circle()
                    .fill(Color(red: 0.55, green: 0.58, blue: 0.62))
                    .frame(width: max(3, h * 0.012), height: max(3, h * 0.012))
                    .position(x: w * 0.03, y: h * 0.04)
                Circle()
                    .fill(Color(red: 0.55, green: 0.58, blue: 0.62))
                    .frame(width: max(3, h * 0.012), height: max(3, h * 0.012))
                    .position(x: w * 0.97, y: h * 0.04)

                // ── Floor (warm beige)
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.86, blue: 0.78),
                        Color(red: 0.82, green: 0.78, blue: 0.70),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: h - floorY)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // ── Floor tile grid (subtle grout lines)
                tileGrid(width: w, height: h, floorY: floorY)

                // ── Baseboard at wall/floor seam
                Rectangle()
                    .fill(Color(red: 0.66, green: 0.62, blue: 0.55))
                    .frame(height: baseboardThickness)
                    .position(x: w / 2, y: floorY + baseboardThickness / 2)
            }
            .clipped()
        }
    }

    /// Subtle floor-tile grout lines giving the floor a sense of depth.
    /// Lines fade out toward the horizon (top of floor).
    private func tileGrid(width w: CGFloat, height h: CGFloat, floorY: CGFloat) -> some View {
        let floorH = h - floorY

        return ZStack {
            // Horizontal grout lines — receding toward the wall
            ForEach(0..<5, id: \.self) { i in
                let fraction = CGFloat(i + 1) / 5.0
                let y = floorY + floorH * fraction
                let opacity = 0.18 + (fraction * 0.18)   // fade-in toward foreground
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(Color(red: 0.55, green: 0.50, blue: 0.40).opacity(opacity),
                        lineWidth: 1)
            }

            // Vertical grout lines — converging slightly to suggest perspective
            ForEach(0..<6, id: \.self) { i in
                let fraction = CGFloat(i) / 5.0
                let xBottom = w * fraction
                let xTop = w * 0.10 + (w * 0.80) * fraction
                Path { p in
                    p.move(to: CGPoint(x: xTop, y: floorY))
                    p.addLine(to: CGPoint(x: xBottom, y: h))
                }
                .stroke(Color(red: 0.55, green: 0.50, blue: 0.40).opacity(0.22),
                        lineWidth: 1)
            }
        }
    }

    // MARK: - Kitchen
    // Warm cream/honey palette — counter horizon, window upper, wood floor

    private var kitchenBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let counterY = h * 0.42
            let floorY   = h * 0.68

            ZStack {
                // Wall
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.99, green: 0.97, blue: 0.90), location: 0.0),
                        .init(color: Color(red: 0.96, green: 0.91, blue: 0.80), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Window glow — upper center-right
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.88).opacity(0.7),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.72, y: 0.08),
                    startRadius: 0,
                    endRadius: w * 0.30
                )

                // Counter surface
                Rectangle()
                    .fill(Color(red: 0.93, green: 0.88, blue: 0.78))
                    .frame(height: h * 0.10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .offset(y: counterY - h / 2 + (h * 0.05))

                // Counter edge line
                Path { p in
                    p.move(to: CGPoint(x: 0, y: counterY))
                    p.addLine(to: CGPoint(x: w, y: counterY))
                }
                .stroke(Color(red: 0.80, green: 0.72, blue: 0.60).opacity(0.8), lineWidth: 2)

                // Floor
                LinearGradient(
                    colors: [
                        Color(red: 0.84, green: 0.74, blue: 0.58),
                        Color(red: 0.76, green: 0.66, blue: 0.50),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: h - floorY)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Floor line
                Path { p in
                    p.move(to: CGPoint(x: 0, y: floorY))
                    p.addLine(to: CGPoint(x: w, y: floorY))
                }
                .stroke(Color(red: 0.68, green: 0.58, blue: 0.44).opacity(0.6), lineWidth: 1.5)

                // Cabinet upper hint — left strip
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.82, blue: 0.68).opacity(0.5))
                    .frame(width: w * 0.22, height: counterY - h * 0.08)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, h * 0.08)
            }
            .clipped()
        }
    }

    // MARK: - Living Room
    // Warm amber/beige — couch silhouette, warm lamp glow, hardwood floor

    private var livingRoomBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.62

            ZStack {
                // Wall
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.98, green: 0.95, blue: 0.88), location: 0.0),
                        .init(color: Color(red: 0.93, green: 0.87, blue: 0.76), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Lamp glow — right side
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.75).opacity(0.55),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.86, y: 0.30),
                    startRadius: 0,
                    endRadius: w * 0.28
                )

                // Window light — upper left (TV wall side)
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.30),
                        Color.clear,
                    ],
                    center: UnitPoint(x: 0.12, y: 0.05),
                    startRadius: 0,
                    endRadius: w * 0.22
                )

                // Hardwood floor
                LinearGradient(
                    colors: [
                        Color(red: 0.78, green: 0.62, blue: 0.44),
                        Color(red: 0.70, green: 0.55, blue: 0.38),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: h - floorY)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Floor line
                Path { p in
                    p.move(to: CGPoint(x: 0, y: floorY))
                    p.addLine(to: CGPoint(x: w, y: floorY))
                }
                .stroke(Color(red: 0.62, green: 0.48, blue: 0.32).opacity(0.7), lineWidth: 1.5)

                // Couch silhouette — center-lower
                couchSilhouette(in: geo)
            }
            .clipped()
        }
    }

    private func couchSilhouette(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        let couchW = w * 0.50
        let couchH = h * 0.18
        let couchX = (w - couchW) / 2
        let couchY = h * 0.58

        return ZStack {
            // Seat
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.68, green: 0.52, blue: 0.38).opacity(0.70))
                .frame(width: couchW, height: couchH)
                .position(x: couchX + couchW / 2, y: couchY + couchH / 2)

            // Back
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.60, green: 0.46, blue: 0.32).opacity(0.65))
                .frame(width: couchW, height: couchH * 0.55)
                .position(x: couchX + couchW / 2, y: couchY - couchH * 0.20)

            // Left arm
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.58, green: 0.44, blue: 0.30).opacity(0.65))
                .frame(width: couchW * 0.10, height: couchH * 0.80)
                .position(x: couchX + couchW * 0.05, y: couchY + couchH * 0.40)

            // Right arm
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.58, green: 0.44, blue: 0.30).opacity(0.65))
                .frame(width: couchW * 0.10, height: couchH * 0.80)
                .position(x: couchX + couchW * 0.95, y: couchY + couchH * 0.40)
        }
    }
}
