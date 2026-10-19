import Foundation

public protocol VoiceProfileRepositoryProtocol: Sendable {
    func fetchProfiles() async throws -> [VoiceProfile]
    func fetchProfile(by id: UUID) async throws -> VoiceProfile?
    func saveProfile(_ profile: VoiceProfile, consent: ConsentContract) async throws
    func updateProfile(_ profile: VoiceProfile) async throws
    func deleteProfile(id: UUID) async throws
}

public protocol UtteranceRepositoryProtocol: Sendable {
    func fetchUtterances(profileId: UUID?) async throws -> [GeneratedUtterance]
    func saveUtterance(_ utterance: GeneratedUtterance) async throws
    func deleteUtterance(id: UUID) async throws
    func clearAllUtterances() async throws
}
