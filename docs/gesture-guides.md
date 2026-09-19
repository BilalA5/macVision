# Skeletal gesture guides

The supplied React prototype's learn/replay flow is implemented natively with SwiftUI. SkeletalHand is an illustrative 21-landmark diagram, not a camera observation or an anatomical 3D model. The selected thumb/finger chains are green; other joints and connections remain quiet neutral tones.

Each gesture row opens a guide with the real configured shortcut and an explicit Practice action. Opening the guide pauses shortcut execution. Onboarding and Practice reuse the pinch guide. Replay demonstrates open, pinch, optional hold/directional movement, and release once. It does not send a shortcut. The task cancels when the view is removed; leaving the active scene resets playback. Reduced Motion shows a static pose and written steps.

Manual checks: replay every gesture; interrupt replay by closing the sheet; select each finger pair; check Reduce Motion; verify no shortcut is sent by replay; verify Practice uses real landmarks. Static renders cover composition, not the animation's timing on hardware.
