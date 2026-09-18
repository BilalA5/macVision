# Live acceptance checklist

Automated tests use synthetic hand coordinates; they cannot verify camera quality, preview alignment, macOS permission dialogs, or how each browser handles shortcuts.

## Capture and setup

- Launch the bundled app: camera stays off, actions stay off.
- Deny camera access: show an actionable error, not an Active label.
- Grant access and activate: the green overlay aligns with the preview, including after resizing.
- Finish setup, quit and reopen: onboarding completion and bindings persist; capture stays off.
- Close the main window: camera keeps running. Open it again from the eye menu.
- Deactivate, including during a pinch: camera indicator turns off and no action occurs.
- Toggle rapidly and sleep/wake: old gestures do not execute; wake leaves capture off.
- Disconnect the camera or revoke permission: capture stops and displays a retry message.

## Recognition in practice mode

- Bring an already pinched hand into view: no completed gesture until it has opened and rearmed.
- Open, pinch, release: one pinch result.
- Hold for over 0.65 seconds, release: one hold result, no separate tap.
- Pinch, move clearly left/right/up/down, release: the intended direction only.
- Move diagonally or ambiguously: no action.
- Hide your hand mid-gesture or show a second hand: cancel; no release action.
- Keep typing/moving normally for several minutes: note any false recognitions before enabling actions.
- Repeat at comfortable distances and in normal room lighting; record failures and perceived lag.

## Actions and calibration

- Use a browser with disposable tabs, then explicitly enable actions.
- Try each default binding, including with a web text field focused.
- Switch to an unsupported app: browser mode sends nothing.
- Record a different shortcut, clear a binding, restart: settings persist.
- Start calibration: actions are disabled. Collect open then closed poses; verify sensitivity persists after restart.
- Give nearly identical calibration poses: reject them and keep the old saved values.
- Remove Accessibility access: actions stop and the app explains why.
- Press Control–Option–Command–G in another app: stop capture immediately; press again to enter practice mode.

## Performance

Use Activity Monitor with the main window open and closed. Observe CPU, memory, energy use, and gesture responsiveness for at least several minutes. Test warm-up separately. The UI processing time is not end-to-end latency. Do not claim latency, battery, or accuracy targets from synthetic tests alone.
