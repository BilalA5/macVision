# Supervision assessment — 2026-09-20

Recommendation: useful as optional offline evaluation tooling; do not add it to macVision's live Swift capture path now.

The [repository](https://github.com/roboflow/supervision) describes a Python, model-agnostic toolkit with annotators and dataset utilities. It consumes results from other models rather than supplying a replacement for Apple's hand-pose inference. [KeyPoints](https://supervision.roboflow.com/latest/keypoint/core/) standardizes landmark outputs; its documented MediaPipe example uses a body PoseLandmarker. A hand-model adapter needs explicit verification or an explicit landmark mapping. [Tracking documentation](https://supervision.roboflow.com/latest/how_to/track_objects/) describes tracking detection identities; that does not itself improve fingertip localization or recognize deliberate pinch/release intent.

## Useful experiment

Use user-provided test clips, with no automatic recording/upload. Run Apple Vision and a candidate hand-specific model on the identical frames. Export timestamps, landmark coordinates/confidences, and actual gesture events. Supervision can help annotate and inspect results offline. Evaluate:

- Gesture precision/recall against labelled events, including ordinary typing and non-gesture hand motion.
- False activations per hour, missed releases, and identity switches with two hands.
- Calibration completion time and failure rate by lighting, hand size, pose, and occlusion.
- Capture-to-event p50/p95 latency, tracking loss, CPU and energy on the target Mac.

Generic object detection accuracy is not sufficient evidence for practical hand control. Choose a replacement only after it beats the native baseline on those criteria and has a viable on-device macOS runtime. No Python runtime, external model, or Supervision dependency has been bundled into the app by this assessment.
