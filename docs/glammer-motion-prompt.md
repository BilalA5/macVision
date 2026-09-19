# macVision — native product and 3D motion brief

Refine the existing macVision interface into a sophisticated native macOS utility. Keep the name exactly macVision. Use the restraint, material quality, lighting and spatial clarity of Apple's AirPods pairing experience as inspiration, while creating original visuals and interaction design. Preserve the graphite/glass palette, green accent, sidebar navigation and generous typography of our existing prototype.

Deliver a working interactive prototype, reusable components, and a motion specification that can be recreated in SwiftUI/AppKit. Clearly label simulated camera, hand tracking and permissions as demo data. Do not invent production integrations or latency results.

## Main experience

Keep four areas: Overview, Gestures, Practice & Calibration, Settings. The utility runs in the background. Opening the app and recalibrating must never be required for ordinary use. Gesture actions must execute immediately; animation is confirmation, never a prerequisite. Browser navigation and configurable shortcuts are the core use cases.

## Signature 3D onboarding

Design an original sculpted hand model with articulated fingers, soft studio lighting, subtle material highlights, ambient occlusion and a quiet grounding shadow. Show a deliberate pinch-and-release from an understandable three-quarter angle, then gently settle into a front-facing pose. Use true articulated 3D geometry where available; disclose any placeholder assets. Avoid emoji, spinning stock objects, neon particles and fake 3D made only from rotating a flat card.

Build an AirPods-quality reveal: a compact invitation expands into a focused setup card, the hand appears as the hero, and a short gesture demonstration explains what to do. Provide replay and skip. Keep decorative sequences confined to onboarding or explicit Learn Gesture interactions. No endless render loop when the window is hidden or the scene is idle.

Each gesture detail should offer a concise 3D demonstration: pinch-release, hold-release, and directional pinch movement. Show the movement path and the configured action with readable keycaps. Do not move text while users read it. Allow the 3D demonstration to transition to the actual camera setup surface without implying that a model is live tracking.

## Notch interaction

The hardware notch is the anchor. The black surface emerges symmetrically from its exact horizontal center, attached to the top screen edge. Both sides expand equally; content reveals downward from behind the notch. It retracts along the same path. Never enter from a corner, slide across the screen or follow the cursor between monitors. A rapid second gesture updates the already-visible feedback and extends its lifetime without replaying the opening animation. Keep routine transitions around 180–250 ms and make them interruptible. Non-notched screens use a compact centered top pill.

Show real product states: off, starting camera, practice, actions enabled, permission required, and action sent. Reserve green success for completed actions. The HUD never steals focus or blocks clicks. Provide reduced-motion and HUD-off alternatives.

## Practice and calibration

Preserve the circular live camera view with green hand landmarks and connecting lines. Include a full-frame option so cropping does not hide hands. Put the optional 3D gesture guide beside the camera, not over the hand. Calibration is optional and saved; clearly separate sample collection, progress, retry and saved state. Actions are paused during practice. Show honest error, no-hand and low-confidence states. Do not show a fabricated accuracy score.

## Visual and engineering details

Use a restrained translucent sidebar, consistent corner radii, thin borders, subtle elevation and clear contrast. Design light and dark themes, keyboard focus, accessible labels, increased contrast, reduced transparency and reduced motion. Use native-looking controls and original hand/vision icon concepts. Avoid duplicating macOS traffic-light controls inside the content.

Deliver: complete screens, one polished onboarding 3D sequence, gesture detail demonstrations, notch entrance/update/exit states, an asset list with license/source information, and exact timings, easing, anchors and interruption behavior for native implementation. Include a static fallback for every 3D scene. Clearly separate shippable UI from illustrative concepts. Prioritize quiet usefulness over spectacle.
