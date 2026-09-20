import Foundation

func expect(_ condition: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) {
    guard condition() else { fatalError("Check failed", file: file, line: line) }
}

@main
struct TestRunner {
    @MainActor static func main() throws {
        pinchRequiresOpeningAndEmitsOnceOnRelease()
        lossCancelsWithoutActionAndRequiresRearming()
        directionalPinchDoesNotAlsoEmitTap()
        holdOnlyCompletesOnRelease()
        staleOrDuplicateTimeCancelsPinch()
        ambiguousDiagonalAndHandJumpCancel()
        pinchRatioAccountsForImageAspectAndRejectsMissingJoints()
        try preferencesPersistAndClearBindings()
        try invalidCalibrationDoesNotReplaceSettings()
        try corruptPreferencesFallBackWithoutCrashing()
        staleSessionAndOutOfOrderResultsAreRejected()
        try fingerSelectionAndShortCalibration()
        calibrationCancellationAndTimeoutClearLiveProgress()
        calibrationAutomaticallyAdvancesAndToleratesBriefLoss()
        let mailbox = LatestFrameMailbox<Int>()
        expect(mailbox.offer(1, isEvent: false))
        expect(!mailbox.offer(2, isEvent: false))
        expect(mailbox.take() == 2)
        expect(mailbox.offer(3, isEvent: true))
        expect(!mailbox.offer(4, isEvent: false))
        expect(mailbox.take() == 3) // Busy UI must not discard an action for a preview frame.
        expect(mailbox.offer(5, isEvent: true))
        expect(!mailbox.offer(6, isEvent: true))
        expect(mailbox.take() == 6 && mailbox.take() == nil)
        print("Passed 15 gesture, settings and delivery tests.")
    }
}
