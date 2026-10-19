import SwiftUI

#if !os(iOS)
/// macOS cross-compilation compatibility layer for iOS-specific navigation and toolbar APIs.
public enum NavigationBarItem {
    public enum TitleDisplayMode: Sendable {
        case automatic
        case inline
        case large
    }
}

public extension View {
    @inlinable
    func navigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
        self
    }
}
#endif
