# ADR-003: ProfileStore — single active profile per device in V1

**Date**: 2026-05-06  
**Status**: Accepted

## Context

The PRD specifies multi-profile support (multiple patients on one hospital iPad is a V2 concern; the locked decision is "no maximum profiles per device"). However, in V1 the primary scenario is:
- One patient per device in hospital mode
- One family account per device in home mode (CloudKit handles this naturally)

The UI flow at launch is: identify which profile to load → PIN unlock → view content. This requires reading the profile's display name before decrypting its content.

## Decision

`ProfileStore` is a single-profile in-memory store that:
1. Persists a `ProfileManifest` (id, name, storageMode, pinHash) in `UserDefaults` — not encrypted, but contains no PHI beyond the patient's first name
2. Encrypts all content (Profile struct, objects, scenes) on disk via `EncryptedLocalRepository`
3. Loads everything into `store.profile`, `store.objects`, `store.scenes` on PIN entry
4. V1 supports exactly one active profile in RAM at a time

`ProfileManifest` in `UserDefaults` enables:
- Showing "Enter PIN for [Name]" on launch without decrypting anything
- Fast PIN verification (compare hashes) before the more expensive AES-GCM decryption

## Consequences

**Good**:
- Simple — no profile-picker screen in V1
- Secure — all health data is encrypted at rest; only patient name is in UserDefaults
- Extensible — to support multi-profile, add a manifest array and a profile-picker view

**Bad / watch**:
- The patient's first name (and PIN hash) are in UserDefaults (not KeyChain, not encrypted). For V1 hospital use, this is acceptable — name is not a unique identifier and PIN hash is non-reversible. V2 should move the manifest to KeyChain if the threat model evolves.
- SHA-256 key derivation from a 4-digit PIN is weak against brute force (10,000 combinations). A hardened KDF (PBKDF2 with salt, stored in KeyChain) is a V2 upgrade.

## Alternatives considered

**Store everything encrypted (no UserDefaults manifest)**: Requires trying all known profile UUIDs on launch — awkward without a public index. Rejected for V1 complexity.

**CloudKit as the profile index**: Only applies to home mode. Hospital mode is offline-only. Dual-path indexing in V1 is too complex.

**Per-profile KeyChain entries for the manifest**: More secure, appropriate for V2+. Deferred to avoid KeyChain entitlement complexity at this stage.
