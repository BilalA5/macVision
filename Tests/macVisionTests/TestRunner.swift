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
        print("Passed 11 gesture, settings and delivery tests.")
    }
}
