import Foundation
import SwiftUI

public enum ProfileSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case name = "Alphabetical"
    
    public var id: String { rawValue }
}

/// ViewModel managing the voice profile library, verified metadata, searching, sorting, and deletion.
@MainActor
@Observable
public final class VoiceLibraryViewModel {
    public var profiles: [VoiceProfile] = []
    public var searchQuery: String = ""
    public var sortOption: ProfileSortOption = .newest
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var editingProfile: VoiceProfile?
    public var updatedNameText: String = ""
    
    private let repository: any VoiceProfileRepositoryProtocol
    
    public init(repository: any VoiceProfileRepositoryProtocol) {
        self.repository = repository
    }
    
    public var filteredProfiles: [VoiceProfile] {
        var result = profiles
        
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        
        switch sortOption {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        return result
    }
    
    public func loadProfiles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profiles = try await repository.fetchProfiles()
        } catch {
            errorMessage = "Failed to load voice profiles: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func renameProfile(_ profile: VoiceProfile, newName: String) async {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var updated = profile
        updated.name = trimmed
        
        do {
            try await repository.updateProfile(updated)
            await loadProfiles()
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }
    
    public func deleteProfile(_ profile: VoiceProfile) async {
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = docs.appendingPathComponent(profile.referenceAudioFilename)
            try? FileManager.default.removeItem(at: audioURL)
            
            try await repository.deleteProfile(id: profile.id)
            await loadProfiles()
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
        }
    }
}
