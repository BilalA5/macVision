import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case overview, gestures, practice, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: "Overview"
        case .gestures: "Gestures"
        case .practice: "Practice & Calibration"
        case .settings: "Settings"
        }
    }
    var symbol: String {
        switch self {
        case .overview: "gauge.with.dots.needle.33percent"
        case .gestures: "hand.pinch"
        case .practice: "viewfinder"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct GestureActivity: Identifiable {
    let id = UUID()
    let date = Date()
    let gesture: GestureKind
    let detail: String
}

struct HUDMessage: Equatable {
    enum Tone { case success, neutral, error }
    let id = UUID()
    let text: String
    let symbol: String
    var tone: Tone = .neutral
    var keycaps: [String] = []
    var detail: String? = nil
    var isAction = false
}
