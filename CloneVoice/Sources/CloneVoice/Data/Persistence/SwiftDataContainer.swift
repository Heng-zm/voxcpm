import Foundation
import SwiftData

/// Configures and manages the SwiftData model container.
public final class SwiftDataContainer: @unchecked Sendable {
    public static let shared = SwiftDataContainer()
    
    public let container: ModelContainer
    
    public init(inMemory: Bool = false) {
        let schema = Schema([
            VoiceProfileEntity.self,
            ConsentContractEntity.self,
            GeneratedUtteranceEntity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
}

/// Actor-isolated repository for Voice Profiles backed by SwiftData.
public actor SwiftDataVoiceProfileRepository: VoiceProfileRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(container: ModelContainer = SwiftDataContainer.shared.container) {
        self.modelContext = ModelContext(container)
    }
    
    public func fetchProfiles() throws -> [VoiceProfile] {
        let descriptor = FetchDescriptor<VoiceProfileEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    public func fetchProfile(by id: UUID) throws -> VoiceProfile? {
        var descriptor = FetchDescriptor<VoiceProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toDomain()
    }
    
    public func saveProfile(_ profile: VoiceProfile, consent: ConsentContract) throws {
        let profileEntity = VoiceProfileEntity(
            id: profile.id,
            name: profile.name,
            createdAt: profile.createdAt,
            referenceAudioFilename: profile.referenceAudioFilename,
            sampleDuration: profile.sampleDuration,
            acousticFeaturesHash: profile.acousticFeaturesHash,
            isBiometricLocked: profile.isBiometricLocked
        )
        
        let consentEntity = ConsentContractEntity(
            id: consent.id,
            timestamp: consent.timestamp,
            termsVersion: consent.termsVersion,
            verificationScriptText: consent.verificationScriptText,
            spokenVerificationAudioFilename: consent.spokenVerificationAudioFilename,
            biometricSignatureSHA256: consent.biometricSignatureSHA256,
            deviceModelIdentifier: consent.deviceModelIdentifier
        )
        
        profileEntity.consentContract = consentEntity
        consentEntity.profile = profileEntity
        
        modelContext.insert(profileEntity)
        modelContext.insert(consentEntity)
        try modelContext.save()
    }
    
    public func updateProfile(_ profile: VoiceProfile) throws {
        var descriptor = FetchDescriptor<VoiceProfileEntity>(
            predicate: #Predicate { $0.id == profile.id }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = profile.name
            existing.isBiometricLocked = profile.isBiometricLocked
            try modelContext.save()
        }
    }
    
    public func deleteProfile(id: UUID) throws {
        var descriptor = FetchDescriptor<VoiceProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
}

/// Actor-isolated repository for Generated Utterances.
public actor SwiftDataUtteranceRepository: UtteranceRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(container: ModelContainer = SwiftDataContainer.shared.container) {
        self.modelContext = ModelContext(container)
    }
    
    public func fetchUtterances(profileId: UUID?) throws -> [GeneratedUtterance] {
        let descriptor: FetchDescriptor<GeneratedUtteranceEntity>
        if let profileId = profileId {
            descriptor = FetchDescriptor<GeneratedUtteranceEntity>(
                predicate: #Predicate { $0.profileId == profileId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<GeneratedUtteranceEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }
    
    public func saveUtterance(_ utterance: GeneratedUtterance) throws {
        let settingsData = try? JSONEncoder().encode(utterance.settings)
        let settingsJSON = settingsData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        let entity = GeneratedUtteranceEntity(
            id: utterance.id,
            profileId: utterance.profileId,
            profileName: utterance.profileName,
            text: utterance.text,
            createdAt: utterance.createdAt,
            audioFilename: utterance.audioFilename,
            duration: utterance.duration,
            c2paManifestDigest: utterance.c2paManifestDigest,
            latencySeconds: utterance.latencySeconds,
            settingsJSON: settingsJSON
        )
        
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    public func deleteUtterance(id: UUID) throws {
        var descriptor = FetchDescriptor<GeneratedUtteranceEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
    
    public func clearAllUtterances() throws {
        let descriptor = FetchDescriptor<GeneratedUtteranceEntity>()
        let all = try modelContext.fetch(descriptor)
        for item in all {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
