import SwiftUI

/// Top-level application tabs for Clone Voice.
public enum AppTab: String, CaseIterable, Identifiable {
    case home = "Conversation"
    case library = "Voice Library"
    case studio = "Studio"
    case history = "History"
    case settings = "Settings"
    
    /// Backward-compatible alias for studio tab
    public static var synthesis: AppTab { .studio }
    
    /// Backward-compatible alias for voice library / deck tab
    public static var deck: AppTab { .library }
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .home:
            return "bubble.left.and.bubble.right.fill"
        case .library:
            return "person.wave.2.fill"
        case .studio:
            return "waveform.badge.mic"
        case .history:
            return "clock.arrow.circlepath"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}

/// Navigation coordinator for modal presentation and tab selection.
@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: AppTab = .home
    public var isEnrollmentPresented = false
    public var activeProfileForSynthesis: VoiceProfile?
    public var presentedProvenanceUtterance: GeneratedUtterance?
    
    public init() {}
}
