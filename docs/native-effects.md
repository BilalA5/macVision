# Native visual effects

Original SwiftUI implementations informed by the public Wensity previews:
- https://ui.wensity.com/components/siri-orb
- https://ui.wensity.com/components/dynamic-island-toast
- https://ui.wensity.com/components/apple-intelligence-glow

No gated component source is included. PrismOrb is a 2D native interpretation of the reference's glass and spectral ribbon, not a WebGL sphere port. It appears in Overview, becomes colorful only with a usable tracked hand, and animates during a held pinch or calibration in an active, visible window. Its timeline is capped at 30 fps.

ActiveEdgeGlow is a click-through screen-edge overlay while both camera capture and shortcut actions are enabled. Settings → Appearance & feedback → Active screen glow switches it off. It uses the main display when enabled and updates after display-configuration changes. The native panel does not become key or take focus. Disabling it removes the hosting view and its timeline. The timeline is capped at 15 fps and runs only during a held pinch. Armed idle control uses a dim static rim; practice, onboarding, permission loss, and unsupported foreground targets hide it. Foreground eligibility uses the same check as shortcut execution. Both effects respect app and system Reduce Motion.

The Dynamic Island adaptation uses the existing centered black notch surface and adds an expanded calibration activity with a trailing progress ring and bottom progress bar. Collection remains visible until the next state instead of expiring as a toast. Completion/cancellation returns to transient feedback. Unrelated upload/music/call demos are not exposed as fake app features.

Validation: build, core tests, static native snapshots. Hardware checks remain: overlay click-through and focused browser input; multiple displays/disconnection; sleep/wake; off/paused/error removes glow; app/system Reduce Motion; CPU and energy usage with effects on versus off. Static screenshots do not validate continuous animation timing or performance.

## Reference fidelity pass

Compared against the public isolated previews on 2026-09-19. The orb now has filled spectral folds, a white caustic, gold leading edge, and upper/lower glass reflections. The screen rim uses a softer pastel palette and a 52-point inward falloff. Expanded calibration follows the reference upload layout (42-point icon, trailing ring, bottom progress bar), with a subtle spring entrance.

These remain native approximations, not verified pixel-identical replicas. The orb uses layered 2D paths rather than the reference's WebGL refraction; the notch silhouette deliberately joins the Mac hardware cutout rather than floating as an iPhone pill. Static renders verify layout/material appearance, not frame-for-frame animation parity. Real-time energy and smoothness comparisons remain manual checks.

## Feature lifecycle integration

Camera startup is a persistent notch activity that ends on readiness, cancellation, or failure. Calibration feedback is emitted by AppState when the accepted sample changes its phase, count, guidance, or usable-hand status; it is no longer independently triggered by view observers. This prevents a calibration reset from replacing camera-off or failure feedback. Explicit calibration cancellation clears progress; saved sensitivity and the intermediate open-pose step have distinct completion messages. Successful actions retain their shortcut keycaps and repeated-action count; rejected actions use error feedback. Accessibility revocation is checked by the capture watchdog and pauses actions even without a new gesture.

Build/core tests and native renders were checked. Live camera interactions, foreground switching, and screen-overlay behavior still require hardware validation; the automated run does not enable the camera or send shortcuts.
