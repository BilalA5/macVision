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

## Native UI acceptance

- Resize the main window from 800 × 600 upward. Each pane should scroll without hiding controls horizontally.
- Switch between System, Light, and Dark; restart and confirm the chosen appearance persists.
- Enable Reduce transparency and Reduce motion in the app and macOS Accessibility settings; verify solid surfaces and immediate HUD changes.
- Navigate using the keyboard; ensure toggles, sidebar buttons, shortcut recording, and onboarding are reachable.
- Replay onboarding from both the main Settings pane and the macOS Settings window: exactly one sheet opens.
- Enter Practice while actions are enabled: actions pause. Enabling actions from the menu returns the main interface to Overview.
- Check camera ring and connected green landmarks against the live image in circular and full preview modes.
- Activate or complete a gesture on a notched MacBook and on an external display: the HUD text stays below hardware, does not steal focus, and dismisses.
- Disable notch feedback: any visible HUD disappears and new gestures do not show it.
- Try Launch at login from the bundled app. Respect any macOS approval step, and verify login launches with the camera off.

### Polished notch feedback

- Trigger an assigned gesture repeatedly: show actual shortcut keycaps, increment the count for identical successful actions, and keep the surface open. A different shortcut resets the count.
- Trigger during the closing transition: reverse smoothly without snapping or letting the old dismissal hide the new message.
- Check camera startup, denied permission, capture failure and practice: neutral/error feedback must not imply a shortcut was sent.
- Check physical-notch center alignment, curved shoulders and mirrored left/right expansion. Move the cursor to another display; feedback stays at the notched display.
- With Reduce Motion enabled, verify a short fade and no silhouette expansion or content translation.
- Test a display without a notch: centered floating pill, no empty cutout area.
- Run `./scripts/render-ui.sh` for static HUD states. These previews validate layout, not live animation timing or hardware placement.
