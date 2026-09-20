import AppKit
import AVFoundation
import Observation

@MainActor @Observable
final class AppState {
    let handTracking = HandTrackingState()
    let presentation = PresentationSettings()
    var selectedSection: AppSection = .overview
    var showsOnboarding = false
    var hasPresentedOnboarding = false
    private(set) var recentActivity: [GestureActivity] = []
    private(set) var hudMessage: HUDMessage?
    let settings = GestureSettings()
    let calibration = CalibrationSession()
    private(set) var isActive = false
    private(set) var isStarting = false
    private(set) var errorMessage: String?
    private(set) var lastGestureText = "No gesture yet"
    private(set) var lastActionText = "Practice mode: actions are off"
    private(set) var actionsEnabled = false
    private(set) var accessibilityGranted = false
    private(set) var activationShortcutAvailable = false
    @ObservationIgnored private var activationHotKey: ActivationHotKey?
    @ObservationIgnored private let executor = ActionExecutor()
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var deliveryGate = TrackingDeliveryGate()
    @ObservationIgnored private var lastSampleAt: Double = 0
    @ObservationIgnored private var watchdog: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored lazy var camera = CameraManager(
        receive: { [weak self] sample in self?.receive(sample) },
        failure: { [weak self] token, message in self?.captureFailed(token: token, message: message) }
    )

    init(enableSystemServices: Bool = true) {
        guard enableSystemServices else { return }
        accessibilityGranted = executor.hasPermission
        activationHotKey = ActivationHotKey { [weak self] in self?.toggleActivation() }
        activationShortcutAvailable = activationHotKey?.isRegistered == true
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.deactivate() }
        })
        // Capture stays off after wake; a fresh explicit activation is required.
        watchdog = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkCaptureHealth() }
        }
    }

    var modeTitle: String {
        if isStarting { return "Starting camera" }
        if errorMessage != nil && !isActive { return "Camera unavailable" }
        if !isActive { return "Off" }
        return actionsEnabled ? "Actions enabled" : "Practice mode"
    }

    var modeDescription: String {
        if isStarting { return "Opening your camera and preparing hand tracking." }
        if let errorMessage, !isActive { return errorMessage }
        if !isActive { return "Your camera is off. Activate when you’re ready to use gestures." }
        return actionsEnabled ? "Gestures send your shortcuts to the foreground app." : "Your camera is on. Try a gesture — no shortcuts will be sent."
    }

    /// Visuals follow accepted tracking samples, never the preview camera alone.
    var hasUsableHand: Bool {
        isActive && handTracking.latestFrame.flatMap {
            PinchMeasurement(frame: $0, finger: settings.preferences.selectedFinger)
        } != nil
    }

    var isGestureEngaged: Bool { hasUsableHand && handTracking.pinchState == .pinched }
    var showsControlGlow: Bool {
        isActive && actionsEnabled && accessibilityGranted && !showsOnboarding
            && !calibration.isCollecting && presentation.showActiveGlow
    }

    var trackingFeedbackText: String {
        guard isActive else { return modeTitle }
        guard hasUsableHand else { return "Bring one hand fully into view" }
        if calibration.isCollecting { return "Hold the calibration pose steady" }
        if isGestureEngaged { return "Pinch held · release to finish" }
        if handTracking.pinchState == .waitingForRelease { return "Open your fingers to get ready" }
        return "Hand ready · pinch to begin"
    }

    var statusText: String { isStarting ? "Starting camera…" : (isActive ? "Active" : "Off") }

    func toggleActivation() {
        if isActive || isStarting { deactivate() } else { activate() }
    }

    func activate() {
        guard !isActive, !isStarting else { return }
        generation = UUID()
        let token = generation
        isStarting = true
        hudMessage = HUDMessage(text: "Starting camera…", symbol: "camera", detail: "Preparing hand tracking", isPersistent: true)
        errorMessage = nil
        Task { @MainActor [weak self] in
            guard let self else { return }
            var authorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                authorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            guard self.generation == token, self.isStarting else { return }
            guard authorized else {
                self.isStarting = false
                self.hudMessage = HUDMessage(text: "Camera permission required", symbol: "lock", tone: .error, detail: "Allow access in System Settings")
                self.errorMessage = "Allow camera access in System Settings → Privacy & Security → Camera."
                return
            }
            self.camera.start(generation: token, preferences: self.settings.preferences) { [weak self] token, error in
                guard let self, self.generation == token else { return }
                self.isStarting = false
                if let error {
                    self.errorMessage = error
                    self.hudMessage = HUDMessage(text: "Camera unavailable", symbol: "exclamationmark.triangle", tone: .error, detail: "Open macVision to review camera setup")
                    return
                }
                self.deliveryGate = TrackingDeliveryGate()
                self.lastSampleAt = ProcessInfo.processInfo.systemUptime
                self.handTracking.setEnabled(true)
                self.isActive = true
                self.hudMessage = HUDMessage(text: "Ready to practice", symbol: "hand.pinch", detail: "Actions paused")
            }
        }
    }

    func deactivate() {
        hudMessage = HUDMessage(text: "Camera off", symbol: "power", tone: .neutral)
        generation = UUID() // Invalidates every queued observation and completion.
        isActive = false
        isStarting = false
        actionsEnabled = false
        handTracking.setEnabled(false)
        calibration.cancel()
        camera.stop()
        lastActionText = "Practice mode: actions are off"
    }

    func setActionsEnabled(_ enabled: Bool) {
        refreshPermissions()
        guard !enabled || (isActive && accessibilityGranted && !calibration.isCollecting && !showsOnboarding) else {
            lastActionText = "Activate the camera and allow Accessibility access first."
            return
        }
        actionsEnabled = enabled
        if enabled { selectedSection = .overview }
        hudMessage = HUDMessage(text: enabled ? "Actions enabled" : "Actions paused",
                                symbol: enabled ? "checkmark" : "pause", tone: enabled ? .success : .neutral)
        lastActionText = enabled ? "Actions enabled" : "Practice mode: actions are off"
        restartRecognition()
    }

    func refreshPermissions() {
        accessibilityGranted = executor.hasPermission
        if actionsEnabled && !accessibilityGranted {
            actionsEnabled = false
            lastActionText = "Accessibility access was removed. Actions are off."
            hudMessage = HUDMessage(text: "Actions paused", symbol: "lock", tone: .error,
                                    detail: "Accessibility access is required")
            restartRecognition()
        }
    }
    func requestAccessibility() { executor.requestPermission(); refreshPermissions() }

    func restartRecognition() {
        guard isActive else { return }
        generation = UUID()
        deliveryGate = TrackingDeliveryGate()
        handTracking.setEnabled(true)
        camera.start(generation: generation, preferences: settings.preferences) { [weak self] token, error in
            if let error { self?.captureFailed(token: token, message: error) }
        }
    }

    func selectPinchFinger(_ finger: PinchFinger) {
        setActionsEnabled(false)
        calibration.cancel()
        settings.selectFinger(finger)
        restartRecognition()
    }

    func beginCalibration(open: Bool) {
        guard isActive else { errorMessage = "Activate the camera before calibrating."; return }
        setActionsEnabled(false)
        if open { calibration.beginOpen(finger: settings.preferences.selectedFinger) } else { calibration.beginClosed(finger: settings.preferences.selectedFinger) }
        presentCalibrationFeedback()
    }

    func cancelCalibration() {
        calibration.cancel()
        if isActive { presentCalibrationFeedback() }
    }

    private func presentCalibrationFeedback() {
        guard isActive else { return }
        if calibration.isCollecting {
            let finger = settings.preferences.selectedFinger.title.lowercased()
            hudMessage = HUDMessage(
                text: calibration.phase == .open ? "Open thumb + \(finger)" : "Hold thumb + \(finger) pinch",
                symbol: "hand.pinch",
                detail: hasUsableHand ? calibration.message : "Bring one hand fully into view",
                progress: Double(calibration.sampleCount) / Double(CalibrationSession.requiredSamples))
        } else if calibration.phase == .complete {
            hudMessage = HUDMessage(text: "Sensitivity saved", symbol: "checkmark", tone: .success,
                                    detail: "Ready for your next session")
        } else if calibration.canCaptureClosed {
            hudMessage = HUDMessage(text: "Open pose captured", symbol: "checkmark", tone: .success,
                                    detail: "Choose Capture closed pinch to continue")
        } else {
            hudMessage = HUDMessage(text: "Calibration stopped", symbol: "hand.pinch", detail: calibration.message)
        }
    }

    func resetCalibration() {
        settings.resetCalibration()
        calibration.cancel()
        restartRecognition()
    }

    private func receive(_ sample: TrackingSample) {
        guard isActive, deliveryGate.accept(
            sequence: sample.sequence, generation: sample.generation, expectedGeneration: generation,
            capturedAt: sample.capturedAt, now: ProcessInfo.processInfo.systemUptime
        ) else { return }
        lastSampleAt = ProcessInfo.processInfo.systemUptime
        let previouslyUsable = hasUsableHand
        handTracking.update(
            handDetected: sample.frame != nil,
            confidentJointCount: sample.frame?.landmarks.values.filter { $0.confidence >= 0.5 }.count ?? 0,
            processingMilliseconds: sample.processingMilliseconds,
            frame: sample.frame, pinchState: sample.pinchState
        )
        if calibration.isCollecting {
            let before = (calibration.phase, calibration.sampleCount, calibration.message)
            let saved = calibration.consume(sample.frame, settings: settings)
            if before != (calibration.phase, calibration.sampleCount, calibration.message) || previouslyUsable != hasUsableHand {
                presentCalibrationFeedback()
            }
            if saved { restartRecognition() }
            return
        }
        guard let gesture = sample.gesture else { return }
        lastGestureText = gesture.title
        let attemptedAction = actionsEnabled
        var sentShortcut: Shortcut?
        defer {
            recentActivity.insert(GestureActivity(gesture: gesture, detail: lastActionText), at: 0)
            recentActivity = Array(recentActivity.prefix(4))
            if let shortcut = sentShortcut {
                hudMessage = HUDMessage(text: shortcut.actionTitle, symbol: "checkmark", tone: .success,
                                        keycaps: shortcut.keycaps, detail: "Shortcut sent", isAction: true)
            } else {
                hudMessage = HUDMessage(text: lastActionText, symbol: gesture.symbol,
                                        tone: attemptedAction ? .error : .neutral)
            }
        }
        guard actionsEnabled else { lastActionText = "Practice: \(gesture.title)"; return }
        guard let shortcut = settings.preferences.bindings[gesture.rawValue] else {
            lastActionText = "No action assigned to \(gesture.title)"
            return
        }
        refreshPermissions()
        if !accessibilityGranted {
            actionsEnabled = false
            lastActionText = "Accessibility access was removed. Actions are off."
            return
        }
        if let error = executor.execute(shortcut, browserOnly: settings.preferences.browserOnly) {
            lastActionText = error
        } else {
            sentShortcut = shortcut
            lastActionText = "Sent \(shortcut.displayName)"
        }
    }

    private func captureFailed(token: UUID, message: String) {
        guard token == generation else { return }
        deactivate()
        errorMessage = message
        hudMessage = HUDMessage(text: "Camera unavailable", symbol: "exclamationmark.triangle", tone: .error)
    }

    private func checkCaptureHealth() {
        guard isActive else { return }
        refreshPermissions()
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            captureFailed(token: generation, message: "Camera access was removed.")
        } else if ProcessInfo.processInfo.systemUptime - lastSampleAt > 3 {
            captureFailed(token: generation, message: "Camera frames stopped arriving. Activate to retry.")
        }
    }
}
