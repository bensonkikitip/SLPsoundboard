# ADR-001: Dual-Mode Storage (Home/Hospital)

**Date**: 2026-05-06
**Status**: Accepted

## Context

SceneTalk must work in two deployment contexts with contradictory requirements:

- **Home** (personal iPad, family-owned iCloud account): natural fit for CloudKit private DB — automatic backup, cross-device sync between family members' iPads, Apple-managed encryption.
- **Hospital** (institutional iPad, no personal iCloud, shared across patients): CloudKit is unavailable or inappropriate. PHI must not leave the device or be associated with a patient's personal Apple ID. Per-patient isolation is required.

## Decision

Implement a **Repository protocol** with two concrete backends:

1. `CloudKitRepository` — home mode, backed by CloudKit private database.
2. `EncryptedLocalRepository` — hospital mode, local-only with CryptoKit symmetric encryption, keyed from the profile's 4-digit PIN (PBKDF2/Argon2 KDF + AES-GCM).

The storage mode is a per-device setting (not per-profile) configured during the first-launch wizard and changeable in Admin settings. All app code above the Repository layer is unaware of which backend is active.

## Consequences

- **Positive**: PHI never reaches our infrastructure or any non-Apple third-party cloud. HIPAA exposure is minimal.
- **Positive**: CloudKit private DB is covered by Apple's data protection; no BAA needed for home use.
- **Positive**: Hospital mode is fully offline-capable; no network dependency.
- **Negative**: Profiles created in hospital mode cannot sync to a home-mode device without an explicit export/import step.
- **Deferred**: V2 may introduce a BAA-covered backend (AWS/GCP) if SLP dashboards and multi-clinician access require cross-device sync in hospital settings.

## Alternatives considered

- **CloudKit-only**: Fails for institutional iPads. Rejected.
- **Local-only for everyone**: No cross-device sync for home families. Rejected.
- **Single backend (self-hosted HIPAA)**: Adds server ops, BAA, and security overhead. Deferred to V2+.
