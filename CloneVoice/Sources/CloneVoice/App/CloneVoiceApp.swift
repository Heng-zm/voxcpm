import SwiftUI
import SwiftData

/// Main application entry point for Clone Voice (iOS 26.0+).
@main
public struct CloneVoiceApp: App {
    @State private var environment = AppEnvironment()
    @State private var router = AppRouter()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedTab) {
                HomeConversationView()
                    .tabItem {
                        Label(AppTab.home.rawValue, systemImage: AppTab.home.iconName)
                    }
                    .tag(AppTab.home)
                
                VoiceLibraryView()
                    .tabItem {
                        Label(AppTab.library.rawValue, systemImage: AppTab.library.iconName)
                    }
                    .tag(AppTab.library)
                
                SpeechGenerationStudioView()
                    .tabItem {
                        Label(AppTab.studio.rawValue, systemImage: AppTab.studio.iconName)
                    }
                    .tag(AppTab.studio)
                
                HistoryView()
                    .tabItem {
                        Label(AppTab.history.rawValue, systemImage: AppTab.history.iconName)
                    }
                    .tag(AppTab.history)
                
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
