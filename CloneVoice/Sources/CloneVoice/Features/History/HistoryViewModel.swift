import Foundation
import SwiftUI

/// ViewModel for managing generation history, persistence verification, playback, and regeneration.
@MainActor
@Observable
public final class HistoryViewModel {
    public var utterances: [GeneratedUtterance] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    private let repository: any UtteranceRepositoryProtocol
    
    public init(repository: any UtteranceRepositoryProtocol) {
        self.repository = repository
    }
    
    public func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await repository.fetchUtterances(profileId: nil)
            // Filter and prune any records whose audio files were physically deleted
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.utterances = fetched.filter { utterance in
                let fileURL = docs.appendingPathComponent(utterance.audioFilename)
                return FileManager.default.fileExists(atPath: fileURL.path)
            }
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func deleteUtterance(_ utterance: GeneratedUtterance) async {
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = docs.appendingPathComponent(utterance.audioFilename)
            try? FileManager.default.removeItem(at: audioURL)
            
            try await repository.deleteUtterance(id: utterance.id)
            await loadHistory()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
    
    public func clearAllHistory() async {
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            for utterance in utterances {
                let audioURL = docs.appendingPathComponent(utterance.audioFilename)
                try? FileManager.default.removeItem(at: audioURL)
            }
            try await repository.clearAllUtterances()
            await loadHistory()
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
    }
}
