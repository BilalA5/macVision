# Interaction refinement — 2026-09-20

## Native UI

Violet controls on graphite/pearl surfaces replace the green accent. Cyan/violet/rose are reserved for the spectral brand mark and activity effects. The camera's real landmark overlay remains available. Native buttons/toggles retain their semantics; primary buttons share a legible capsule style, a restrained 120 ms press response, and Reduce Motion support.

Notch hosting-window bounds remain fixed across transient and calibration messages. The drawn surface interpolates inside them, with larger tangent-smooth cubic bottom corners, centered expansion, and a non-bouncing 260 ms entrance/200 ms exit. Offscreen renders cover intermediate shape stages, light/dark appearances, and compact windows; these do not prove live frame-rate performance.

References: [Explore SwiftUI](https://exploreswiftui.com/) for native control patterns and [SwiftUX's morphing action menu](https://www.swiftux.app/uicomponents/morphing-action-menu) for a single surface changing shape. The implementation remains compatible with the project's macOS 14 minimum; no third-party UI runtime or gated component source was added.

## Capture and calibration

The nominal 30 fps processing gate now uses a deadline with scheduling tolerance, avoiding repeated skips when callbacks arrive slightly early. UI delivery accepts up to the capture rate and immediately publishes recognition-state changes. A single-slot mailbox coalesces preview updates while preserving completed gestures over preview-only frames; the existing generation and stale-frame checks still apply. Delivery remains bounded, with late-frame rejection. Where supported, capture requests native full-range bi-planar YUV instead of RGB conversion. See [Apple's frame-drop guidance](https://developer.apple.com/library/archive/technotes/tn2445/_index.html).

Calibration takes six stable observations per pose after a 250 ms settling period. It advances automatically from open to closed, requires a meaningful reduction in pinch distance, pauses through a short dropout, and slides past unstable samples instead of discarding an entire attempt. It does not lower fingertip confidence thresholds or synthesize missing landmarks. Calibration and action recognition now agree that the palm must span at least 20 image pixels.

Practice diagnostics show inference duration, frame age at MainActor delivery, and smoothed delivered updates/second. Frame age is not complete user-intent-to-action latency. Apple Vision's learned model was not retrained or replaced. Detection accuracy and hardware speedup remain unmeasured; use the displayed diagnostics and labelled real-world trials before claiming improvement.

Validation: 15 core regression groups pass, including automatic pose transitions, rejection of unchanged open poses, brief dropout tolerance, cancellation/late observations, and the shared hand-size gate. Native UI previews were rendered and inspected. Live camera, multi-display transitions, keyboard focus, and energy use remain hardware checks.
