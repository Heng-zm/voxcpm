import SwiftUI
import SwiftData

/// Main application entry point for Clone Voice.
@main
public struct CloneVoiceApp: App {
    @State private var environment = AppEnvironment()
    @State private var router = AppRouter()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedTab) {
                VoiceDeckView()
                    .tabItem {
                        Label(AppTab.deck.rawValue, systemImage: AppTab.deck.iconName)
                    }
                    .tag(AppTab.deck)
                
                SpeechGenerationStudioView()
                    .tabItem {
                        Label(AppTab.synthesis.rawValue, systemImage: AppTab.synthesis.iconName)
                    }
                    .tag(AppTab.synthesis)
                
                UtteranceLibraryView()
                    .tabItem {
                        Label(AppTab.library.rawValue, systemImage: AppTab.library.iconName)
                    }
                    .tag(AppTab.library)
                
                SettingsView()
                    .tabItem {
                        Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                    }
                    .tag(AppTab.settings)
            }
            .tint(DesignTokens.Colors.acousticCyan)
            .environment(environment)
            .environment(router)
        }
    }
}
