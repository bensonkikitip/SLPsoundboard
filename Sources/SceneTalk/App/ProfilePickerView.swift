import SwiftUI

/// Shown when multiple profiles exist on this device and none is currently unlocked.
/// Each card shows the profile name. Tapping selects it for PIN unlock.
/// An "Add Profile" button opens the new-profile wizard.
struct ProfilePickerView: View {

    let manifests: [ProfileManifest]
    let onSelect: (ProfileManifest) -> Void
    let onAddProfile: () -> Void

    // Grid layout — two columns on iPad
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 20)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(manifests) { manifest in
                        ProfileCardView(manifest: manifest) {
                            onSelect(manifest)
                        }
                    }
                    AddProfileCard(action: onAddProfile)
                }
                .padding(32)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text(String(localized: "Who's using SceneTalk?"))
                .font(.largeTitle.weight(.bold))

            Text(String(localized: "Choose a profile to continue"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 56)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Profile card

private struct ProfileCardView: View {
    let manifest: ProfileManifest
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(initials)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 4) {
                    Text(manifest.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(String(localized: "\(manifest.name), locked"))
        .accessibilityHint(String(localized: "Tap to unlock with PIN"))
    }

    /// Up to two initials from the profile name
    private var initials: String {
        let parts = manifest.name.split(separator: " ")
        switch parts.count {
        case 0: return "?"
        case 1: return String(parts[0].prefix(1)).uppercased()
        default: return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
    }
}

// MARK: - Add profile card

private struct AddProfileCard: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 72, height: 72)
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(String(localized: "Add Profile"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(String(localized: "Add a new profile"))
    }
}
