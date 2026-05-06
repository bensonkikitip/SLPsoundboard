# SceneTalk (working name)

Familiar-scene AAC iPad app for TBI patients with acquired speech impairments.

The wedge: AAC where the symbols are photos of the patient's actual home, and the voices are the patient's actual family. Therapy benefits (faster verbal recovery, per SLP literature on familiar audiovisual context) ride along.

## V1 scope

- iPad only, iPadOS 17+
- Family + SLP author; patient uses
- Single-tap-speak (no sentence assembly in V1)
- Layered scenes: background photo + tappable object placements
- Reusable per-profile Object Library
- iOS 17+ Vision lift-subject for cutout authoring
- Dual storage: home (CloudKit private DB) / hospital (local-only encrypted)
- English + Spanish at launch
- No backend. No third-party clouds with PHI.

## Repo layout

- `Sources/SceneTalk/` — app source
- `Tests/SceneTalkTests/` — XCTest target
- `docs/adr/` — architectural decision records
- `CONTEXT.md` — domain glossary
- `project.yml` — xcodegen project definition (run `xcodegen generate` to (re)create the .xcodeproj)

## Building

```sh
brew install xcodegen   # one-time
xcodegen generate
open SceneTalk.xcodeproj
```

Or from CLI:

```sh
xcodebuild -project SceneTalk.xcodeproj -scheme SceneTalk -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test
```

## Working notes

- Source of truth for the V1 PRD lives in `~/.claude/plans/lets-work-on-planning-inherited-moore.md` until implementation is complete; will be archived once V1 ships.
- TDD discipline: red-green-refactor, vertical slices, integration-style tests through public APIs.
- Branch per slice (`feat/v1-skeleton`, `feat/v1-profile-pin`, etc.).
