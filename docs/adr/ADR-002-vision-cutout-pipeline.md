# ADR-002: On-Device Vision Framework for Cutout Authoring

**Date**: 2026-05-06
**Status**: Accepted

## Context

A core differentiator of SceneTalk is that every Object can have a real photo of the familiar thing as its image. Creating transparent-background PNG cutouts from photos is technically non-trivial and the friction of that step determines whether family members actually populate Scenes.

Options:
1. **iOS 17+ Vision `VNGenerateForegroundInstanceMaskRequest`** — the same API behind iOS's "tap and hold to lift subject" in Photos. Runs entirely on-device. No data leaves the iPad.
2. **Third-party API (remove.bg, Photoroom API)** — higher quality on some images, but photo (potentially showing PHI context) is sent to a third-party server.
3. **Manual masking brush tool** — maximum control, unusable friction.
4. **Stock images only** — no custom cutouts. Loses the familiar-environment differentiator.

## Decision

Use **`VNGenerateForegroundInstanceMaskRequest`** (iOS 17+, on-device). Minimum deployment target is already iPadOS 17 for other reasons, so this API is available on all supported devices.

Flow: take/pick photo → Vision extracts foreground mask → app composites mask onto transparent background → family confirms/adjusts → PNG saved to Object.

## Consequences

- **Positive**: Zero PHI transmission. On-device = fast, no network required.
- **Positive**: No third-party SDK, no API key management, no cost-per-call.
- **Positive**: Quality is good for common real-world objects and people (Apple has invested heavily in this pipeline).
- **Negative**: Quality degrades on visually complex backgrounds (cluttered shelves, transparent objects, hair close to busy backgrounds). Family can retake the photo with a cleaner background. We document this in onboarding.
- **Negative**: Locks minimum deployment to iPadOS 17+ (already the stated requirement).

## Alternatives considered

- **remove.bg / Photoroom API**: Rejected due to PHI risk (family photos may contain patient/environment PII) and ongoing API cost.
- **Manual brush**: Rejected — unusable for this user population.
