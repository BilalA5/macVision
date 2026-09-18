import AppKit
import AVFoundation
import Observation

@MainActor @Observable
final class AppState {
    let handTracking = HandTrackingState()
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

    init() {
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

    var statusText: String { isStarting ? "Starting camera…" : (isActive ? "Active" : "Off") }

    func toggleActivation() {
        if isActive || isStarting { deactivate() } else { activate() }
    }

    func activate() {
        guard !isActive, !isStarting else { return }
        generation = UUID()
        let token = generation
        isStarting = true
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
                self.errorMessage = "Allow camera access in System Settings → Privacy & Security → Camera."
                return
            }
            self.camera.start(generation: token, preferences: self.settings.preferences) { [weak self] token, error in
                guard let self, self.generation == token else { return }
                self.isStarting = false
                if let error { self.errorMessage = error; return }
                self.deliveryGate = TrackingDeliveryGate()
                self.lastSampleAt = ProcessInfo.processInfo.systemUptime
                self.handTracking.setEnabled(true)
                self.isActive = true
            }
        }
    }

    func deactivate() {
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
        guard !enabled || (isActive && accessibilityGranted && !calibration.isCollecting) else {
            lastActionText = "Activate the camera and allow Accessibility access first."
            return
        }
        actionsEnabled = enabled
        lastActionText = enabled ? "Actions enabled" : "Practice mode: actions are off"
        restartRecognition()
    }

    func refreshPermissions() { accessibilityGranted = executor.hasPermission }
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

    func beginCalibration(open: Bool) {
        guard isActive else { errorMessage = "Activate the camera before calibrating."; return }
        setActionsEnabled(false)
        if open { calibration.beginOpen() } else { calibration.beginClosed() }
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
        handTracking.update(
            handDetected: sample.frame != nil,
            confidentJointCount: sample.frame?.landmarks.values.filter { $0.confidence >= 0.5 }.count ?? 0,
            processingMilliseconds: sample.processingMilliseconds,
            frame: sample.frame, pinchState: sample.pinchState
        )
        if calibration.isCollecting {
            if calibration.consume(sample.frame, settings: settings) { restartRecognition() }
            return
        }
        guard let gesture = sample.gesture else { return }
        lastGestureText = gesture.title
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
            lastActionText = "Sent \(shortcut.displayName)"
        }
    }

    private func captureFailed(token: UUID, message: String) {
        guard token == generation else { return }
        deactivate()
        errorMessage = message
    }

    private func checkCaptureHealth() {
        guard isActive else { return }
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            captureFailed(token: generation, message: "Camera access was removed.")
        } else if ProcessInfo.processInfo.systemUptime - lastSampleAt > 3 {
            captureFailed(token: generation, message: "Camera frames stopped arriving. Activate to retry.")
        }
    }
}
