import SwiftUI

/// Admin settings panel — language, backup, and restore.
/// Presented as a sheet from the admin shell.
struct AdminSettingsView: View {

    @Binding var profile: Profile
    let onDone: () -> Void

    // Export state
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                if profile.storageMode == .hospital {
                    backupSection
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done"), action: onDone)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Language section

    private var languageSection: some View {
        Section {
            ForEach(Language.allCases, id: \.self) { lang in
                LanguageRow(
                    lang: lang,
                    isSelected: profile.language == lang,
                    onSelect: {
                        profile.language = lang
                        LanguageOverride.apply(lang)
                    }
                )
            }
        } header: {
            Text(String(localized: "Language"))
        } footer: {
            Text(String(localized: "Changes take effect the next time you return to patient mode."))
                .font(.footnote)
        }
    }

    // MARK: - Backup section

    private var backupSection: some View {
        Section {
            Button {
                Task { await exportProfile() }
            } label: {
                HStack {
                    if isExporting {
                        ProgressView().padding(.trailing, 4)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(String(localized: "Export Profile"))
                }
            }
            .disabled(isExporting)

            if let err = exportError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(String(localized: "Backup"))
        } footer: {
            Text(String(localized: "Export an encrypted backup. Share via AirDrop or Files."))
                .font(.footnote)
        }
    }

    private func exportProfile() async {
        isExporting = true
        exportError = nil
        let exporter = ProfileBundleExporter()
        do {
            let url = try await exporter.export(profileId: profile.id)
            exportURL = url
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
    }
}

// MARK: - Language row

private struct LanguageRow: View {
    let lang: Language
    let isSelected: Bool
    let onSelect: () -> Void

    private var flag: String  { lang == .english ? "🇺🇸" : "🇪🇸" }
    private var name: String  { lang == .english ? "English" : "Español" }
    private var sub: String   { lang == .english ? "English" : "Spanish" }

    var body: some View {
        HStack {
            Text(flag)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body)
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(name)
        .accessibilityHint(sub)
    }
}

// MARK: - Share sheet

import UIKit

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Language override helper

/// Applies a language override so the system picks the correct
/// `Localizable.xcstrings` entry on next view refresh.
///
/// This sets `AppleLanguages` in `UserDefaults` — the standard iOS
/// per-app language override. The caller is responsible for triggering
/// a view hierarchy refresh (e.g. by toggling a state variable).
enum LanguageOverride {
    static func apply(_ language: Language) {
        let code: String
        switch language {
        case .english: code = "en"
        case .spanish: code = "es"
        }
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    /// Returns the currently-applied override, if any.
    static var current: String? {
        (UserDefaults.standard.array(forKey: "AppleLanguages") as? [String])?.first
    }
}
