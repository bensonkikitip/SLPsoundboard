# SceneTalk — Domain Glossary

Use the terms below exactly. Do not drift to synonyms or introduce new vocabulary without updating this file.

---

## Core Concepts

**Profile**
A single patient's entire configuration: their Object Library, Scenes, Essentials config, layout preferences, language setting, PIN hash, and storage mode (home or hospital). Multiple profiles can coexist on one device. Each profile is independently isolated — no cross-profile data sharing.

**Patient mode**
The locked-down, full-screen experience the patient uses directly. Only shows the Essentials bar + Scene grid (and individual Scenes when navigated into). No destructive UI is reachable without PIN entry. The default app state on launch.

**Admin mode**
The PIN-gated authoring and configuration experience, accessed by family or SLP. Contains: Object Library, Scene editor, Profile settings, layout tunables, language toggle, backup/export. Entered via a lock icon → 4-digit PIN.

**Essentials bar**
A persistent strip of configurable communication shortcuts (yes, no, pain, help, nurse, water, bathroom, cold, hot — defaults). Present on every screen in Patient mode. Each essential is a single tap that speaks immediately. Position (top/bottom/left/right) is a per-profile Admin setting.

**Scene**
A communication board composed of one background image and zero or more Placements. Examples: Hospital Room, Kitchen, Bedroom, Living Room. Patient taps a Scene tile in the Scene grid to enter it.

**Scene grid**
The home screen in Patient mode, showing all available Scenes as tiles. Always accessible from within any Scene via a back button.

**Background image**
The full-bleed photo used as the visual context for a Scene (e.g., a photo of the patient's actual kitchen).

**Object**
The reusable unit of communication content. Each Object belongs to one Profile's Object Library and has: a label (display text), a transcript (what TTS or the voice clip represents), an image asset (PNG with transparency — a cutout), an optional audio asset (family/SLP voice recording), a `kind` (noun or phrase-intent), and a TTS fallback string. An Object is authored once and can be placed in multiple Scenes.

**Object Library**
The per-profile collection of all Objects. Analogous to a "symbol library" in traditional AAC. Family and SLP use Admin mode to add, edit, or delete Objects here.

**Placement**
A single instance of an Object positioned within a specific Scene. Stores: `objectId`, `x`, `y`, `width`, `height`, `zIndex`. The same Object can have many Placements across different Scenes. Editing an Object updates all its Placements (they share the Object's image and audio).

**Noun object** (`kind: .noun`)
An Object representing a physical thing (apple, bed, water cup, restroom sign). Tapping speaks the object's label/audio.

**Phrase-intent object** (`kind: .phraseIntent`)
An Object representing a communicative need or action ("Need bathroom", "Call nurse", "I'm in pain", "Adjust bed"). Same data model as noun, different semantic meaning and authoring intent.

**Voice clip**
A short audio recording (typically 1–5 seconds) attached to an Object, made by a family member or SLP using the in-app recorder. When present, this plays instead of TTS when the patient taps the Object.

**TTS fallback**
`AVSpeechSynthesizer` with an Apple system voice, speaking the Object's `ttsText` (or label if `ttsText` is absent). Used when no voice clip exists, or for Essentials that haven't been re-recorded. Voice locale is determined by the Profile's language setting.

**Cutout pipeline**
The authoring flow for creating an Object's image asset. Family takes or selects a photo → app extracts the subject using `VNGenerateForegroundInstanceMaskRequest` (iOS 17+, on-device, no PHI transmission) → family confirms/trims the result → transparent PNG is saved to the Object.

**Hospital starter scene**
The default Scene provisioned on first launch (and restorable from Admin). Contains stock phrase-intent and noun objects relevant to an inpatient stay: "Call nurse", "Need bathroom", "I'm in pain", "Adjust bed", "Need water", "Need pillow", "TV please", bed, water cup, IV pole, family chair, restroom sign. All stock objects use TTS. Family/SLP replace with voice clips over time.

**Home mode**
Storage mode where a Profile syncs via CloudKit private database (tied to the device's Apple ID). Suitable for personal iPads used by one patient family.

**Hospital mode**
Storage mode where all Profile data stays on-device only. Per-profile encryption using CryptoKit (4-digit PIN → derived key). No iCloud, no cloud sync. PHI never leaves the device. Profile can be backed up via encrypted export.

**Repository**
The protocol abstraction over storage. Two concrete implementations: `CloudKitRepository` (home mode) and `EncryptedLocalRepository` (hospital mode). Nothing above the Repository layer knows which is in use.

**`.scenetalk` bundle**
The encrypted export file format for Profile backup (hospital mode). A single file containing: background images, cutout PNGs, audio clips, and a JSON manifest — encrypted with the Profile PIN. Restored via "Import Profile" on any device.

**Tracer-bullet slice**
A thin vertical cut through every layer of the app (data model → storage → UI → test) that is independently buildable and demoable. V1 is broken into 18 slices.

---

## Users

**Patient** — TBI patient with acquired speech impairment. Uses Patient mode only.
**Family member** — Caregiver who authors content and manages the Profile in Admin mode.
**SLP (Speech-Language Pathologist)** — Recommends the app; may also co-author content in Admin mode using a PIN shared by family.

---

## Abbreviations

| Term | Meaning |
|---|---|
| TBI | Traumatic Brain Injury |
| AAC | Augmentative and Alternative Communication |
| SLP | Speech-Language Pathologist |
| VSD | Visual Scene Display (the research paradigm this app implements) |
| TTS | Text-to-Speech (Apple AVSpeechSynthesizer system voices) |
| PHI | Protected Health Information |
| PIN | 4-digit passcode used to gate Admin mode per-profile |

---

## Out-of-vocabulary (do not use these — use the canonical term above instead)

| Avoid | Use instead |
|---|---|
| "card", "button", "tile" (for communication symbols) | **Object** |
| "page", "board" | **Scene** |
| "scene library", "scene collection" | **Scene grid** |
| "vocabulary", "symbol" | **Object** |
| "lock", "kiosk", "restriction" | **Patient mode** / **Admin mode** |
| "caretaker", "guardian" | **Family member** |
| "clinician", "therapist" (in code) | **SLP** |
| "cloud save", "iCloud sync" | **Home mode** / CloudKit |
| "offline mode" | **Hospital mode** |
