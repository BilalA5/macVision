import Carbon

/// Carbon hot keys do not require a keyboard-monitoring permission.
@MainActor
final class ActivationHotKey {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let onPress: () -> Void
    private(set) var isRegistered = false

    init(onPress: @escaping () -> Void) {
        self.onPress = onPress
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                Unmanaged<ActivationHotKey>.fromOpaque(context).takeUnretainedValue().onPress()
            }
            return noErr
        }, 1, &eventType, context, &handler)
        guard handlerStatus == noErr else { return }
        let identifier = EventHotKeyID(signature: 0x4D56534E, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_G), UInt32(controlKey | optionKey | cmdKey),
                                        identifier, GetApplicationEventTarget(), 0, &hotKey)
        isRegistered = status == noErr
    }

    func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
        hotKey = nil
        handler = nil
        isRegistered = false
    }
}
