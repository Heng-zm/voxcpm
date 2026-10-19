import SwiftUI

/// Top-level application tabs.
public enum AppTab: String, CaseIterable, Identifiable {
    case deck = "Profiles"
    case synthesis = "Studio"
    case library = "Library"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .deck:
            return "person.wave.2.fill"
        case .synthesis:
            return "waveform.badge.mic"
        case .library:
            return "books.vertical.fill"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}

/// Navigation coordinator for modal flows.
@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: AppTab = .deck
    public var isEnrollmentPresented = false
    public var activeProfileForSynthesis: VoiceProfile?
    public var presentedProvenanceUtterance: GeneratedUtterance?
    
    public init() {}
}
