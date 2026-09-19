# macVision interface style

Use native SwiftUI controls, instant sidebar navigation and a restrained green accent. The shared design system owns 26 pt pane headings, 13 pt row titles, 14 pt panel corners, 18 pt panel padding and 22 pt section spacing. Panels use subtle depth in dark mode and white surfaces in light mode; Increased Contrast strengthens their outlines.

Overview prioritizes activation, action permissions, and an actionable empty state. Gestures groups all six bindings into one surface. Practice gives the real camera preview a dedicated panel and separates optional calibration. Settings uses consistent icon-led rows. Onboarding repeats the same feature-tile vocabulary and shows the current step. Menu-bar controls retain native focus behavior and explicit accessible names.

Keep routine controls immediate. Do not add page entrance choreography, perpetual decorative loops, or simulated tracking visuals. The green hand landmark map remains live camera-derived content.

Validate changes with `./scripts/render-ui.sh` in both themes and at the minimum window size. Offscreen renders do not reproduce a key window's native button emphasis, live transparency, keyboard focus, or camera behavior; check these in the running app.
