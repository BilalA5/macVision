# macVision

A native Swift macOS menu-bar utility for hands-free browser shortcuts. Requires macOS 14 or newer and Apple Command Line Tools. Xcode IDE is not required.

## Develop

```sh
./scripts/test.sh
./scripts/run.sh
```

Quit the old app from its menu before running a new build. Closing the main window keeps the utility running. The test runner uses `swiftc` and does not require XCTest or Swift Testing. Build products stay in ignored `.build/`, `build/`, and `dist/` directories.

## First use

1. Open macVision, allow camera access, and activate.
2. Check the green joint overlay from a comfortable sitting position. One whole hand must be visible. Good lighting matters.
3. Practice opening your thumb/index, pinching, then releasing. Watch the last-gesture label. Actions are off initially.
4. Optionally capture open and closed poses in calibration. Sensitivity and bindings persist across launches; recalibration is not needed each session.
5. Review the bindings, allow Accessibility access, then enable actions. Switch to your browser to use them.

The global shortcut **Control–Option–Command–G** activates or stops capture. If another app owns it, use the eye menu. Deactivation and sleep disable actions; activation starts in practice mode. There is no camera capture on app launch.

## Default browser actions

| Gesture | Shortcut | Intended browser action |
| --- | --- | --- |
| Pinch and release | Control–Tab | Next tab |
| Hold and release | Control–Shift–Tab | Previous tab |
| Pinch, move left, release | Command–[ | Back |
| Pinch, move right, release | Command–] | Forward |
| Pinch, move up, release | Page Up | Scroll up |
| Pinch, move down, release | Page Down | Scroll down |

Each shortcut can be recorded or cleared. Browser-only mode supports Safari, Chrome, Firefox, Edge, Brave, and Arc by bundle identifier. Turn that mode off for shortcuts in other apps. Shortcuts follow the foreground app's key handling; a focused text field or website can change their effect. Keyboard bindings use physical key codes, so review them after changing keyboard layouts.

The MVP supports custom **bindings for six gesture types**, not training arbitrary new hand poses. Media controls, learned poses, per-app profiles, and window positioning are future extensions.

## Architecture for UI work

- `AppState`: activation, permission flow, action enablement, failure recovery, latest user feedback. UI should call its methods rather than starting capture directly.
- `CameraManager`: serial capture configuration and camera lifecycle. Reports start failures and runtime stops.
- `HandTracker`: serial Vision work, maximum two-hand ambiguity check, 30 Hz processing cap, 15 Hz preview publication, bounded delivery to the main actor. Completed gestures bypass the preview throttle.
- `HandFrame` / `PinchMeasurement`: immutable landmark data and scale-normalized pinch distance.
- `PinchRecognizer` / `GestureEngine`: confidence gating, separate open/close thresholds, temporal confirmation, hold/direction classification, cancellation and cooldown.
- `TrackingDeliveryGate`: rejects old activations, duplicate/out-of-order results, and results older than 250 ms.
- `GestureSettings`: versioned local persistence and editable bindings.
- `CalibrationSession`: optional stable open/closed pose sampling.
- `ActionExecutor`: Accessibility check and paired key-down/key-up events. Never sends gestures to macVision itself.
- `CameraPreview`: the green overlay is deliberately retained as a setup/calibration component.

No camera frames are recorded or uploaded. Closing the preview does not own or stop the tracking pipeline. Only one queued UI delivery is allowed; if the UI is busy, stale work is dropped. Dropping an action is preferable to executing it late.

The processing number measures Vision/recognizer computation, **not** full gesture-to-action latency. Defaults (50 ms confirmation, 0.65 s hold, 0.4 s cooldown) are starting points and still need real-world usability/performance measurements. Turning the hand sideways, occlusion, small hands in the image, and poor light can reduce reliability. Two visible hands cancel recognition.

## Package

```sh
./scripts/build-app.sh release
./scripts/package-dmg.sh
```

The local app is created at `build/macVision.app`; the installer is `dist/macVision.dmg` with an Applications shortcut. By default it is ad-hoc signed for local development. To use a Developer ID certificate, set `MACVISION_SIGN_IDENTITY` to the certificate name. Public distribution additionally requires Apple notarization/stapling; these scripts do not submit anything to Apple. Builds target the current Mac architecture.

Keep the bundle ID stable to preserve permissions. Ad-hoc rebuilds can require re-granting Accessibility access. UI/icon polish, notch animation, installer artwork, and public-release signing are separate from the working MVP foundation.

See [the live test checklist](docs/manual-testing.md) before treating gesture accuracy or background use as verified.
