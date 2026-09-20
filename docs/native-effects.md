# Native visual effects

Original SwiftUI implementations informed by the public Wensity previews:
- https://ui.wensity.com/components/siri-orb
- https://ui.wensity.com/components/dynamic-island-toast
- https://ui.wensity.com/components/apple-intelligence-glow

No gated component source is included. PrismOrb is a 2D native interpretation of the reference's glass and spectral ribbon, not a WebGL sphere port. It appears in Overview, becomes colorful with active camera capture, and animates only in an active, visible window. Its timeline is capped at 30 fps.

ActiveEdgeGlow is a click-through screen-edge overlay while both camera capture and shortcut actions are enabled. Settings → Appearance & feedback → Active screen glow switches it off. It uses the main display when enabled and updates after display-configuration changes. The native panel does not become key or take focus. Disabling it removes the hosting view and its timeline. The timeline is capped at 15 fps. Both effects respect app and system Reduce Motion.

The Dynamic Island adaptation uses the existing centered black notch surface and adds an expanded calibration activity with a trailing progress ring and bottom progress bar. Collection remains visible until the next state instead of expiring as a toast. Completion/cancellation returns to transient feedback. Unrelated upload/music/call demos are not exposed as fake app features.

Validation: build, core tests, static native snapshots. Hardware checks remain: overlay click-through and focused browser input; multiple displays/disconnection; sleep/wake; off/paused/error removes glow; app/system Reduce Motion; CPU and energy usage with effects on versus off. Static screenshots do not validate continuous animation timing or performance.

## Reference fidelity pass

Compared against the public isolated previews on 2026-09-19. The orb now has filled spectral folds, a white caustic, gold leading edge, and upper/lower glass reflections. The screen rim uses a softer pastel palette and a 52-point inward falloff. Expanded calibration follows the reference upload layout (42-point icon, trailing ring, bottom progress bar), with a subtle spring entrance.

These remain native approximations, not verified pixel-identical replicas. The orb uses layered 2D paths rather than the reference's WebGL refraction; the notch silhouette deliberately joins the Mac hardware cutout rather than floating as an iPhone pill. Static renders verify layout/material appearance, not frame-for-frame animation parity. Real-time energy and smoothness comparisons remain manual checks.
