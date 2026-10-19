import Foundation
import SwiftUI

/// ViewModel driving the Voice Profile Deck gallery.
@MainActor
@Observable
public final class VoiceDeckViewModel {
    public var profiles: [VoiceProfile] = []
    public var selectedProfileIndex: Int = 0
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let repository: any VoiceProfileRepositoryProtocol
    private let biometricAuth: BiometricAuthServiceProtocol
    
    public init(
        repository: any VoiceProfileRepositoryProtocol,
        biometricAuth: BiometricAuthServiceProtocol
    ) {
        self.repository = repository
        self.biometricAuth = biometricAuth
    }
    
    public var currentProfile: VoiceProfile? {
        guard !profiles.isEmpty, selectedProfileIndex < profiles.count else { return nil }
        return profiles[selectedProfileIndex]
    }
    
    public func loadProfiles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profiles = try await repository.fetchProfiles()
            if selectedProfileIndex >= profiles.count {
                selectedProfileIndex = max(0, profiles.count - 1)
            }
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func authorizeProfileAccess(profile: VoiceProfile) async -> Bool {
        guard profile.isBiometricLocked else { return true }
        
        do {
            return try await biometricAuth.authenticate(
                reason: "Authorize access to use '\(profile.name)' voice model."
            )
        } catch {
            errorMessage = "Biometric authentication failed."
            return false
        }
    }
    
    public func deleteProfile(_ profile: VoiceProfile) async {
        do {
            try await repository.deleteProfile(id: profile.id)
            await loadProfiles()
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
        }
    }
}
