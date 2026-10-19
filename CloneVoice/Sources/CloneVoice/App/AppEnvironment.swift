import Foundation
import SwiftData
import SwiftUI

/// Central dependency injection environment for Clone Voice.
@MainActor
@Observable
public final class AppEnvironment {
    public let profileRepository: any VoiceProfileRepositoryProtocol
    public let utteranceRepository: any UtteranceRepositoryProtocol
    public let audioEngine: AudioEngineActor
    public let streamPlayer: AudioStreamPlayer
    public let inferenceClient: VoxCPMInferenceClient
    public let biometricAuth: BiometricAuthService
    public let watermarkService: C2PAWatermarkService
    
    public init(
        inMemory: Bool = false,
        backendURL: URL = URL(string: "http://127.0.0.1:8000")!
    ) {
        let container = SwiftDataContainer(inMemory: inMemory).container
        self.profileRepository = SwiftDataVoiceProfileRepository(container: container)
        self.utteranceRepository = SwiftDataUtteranceRepository(container: container)
        self.audioEngine = AudioEngineActor()
        self.streamPlayer = AudioStreamPlayer()
        self.inferenceClient = VoxCPMInferenceClient(baseURL: backendURL)
        self.biometricAuth = BiometricAuthService.shared
        self.watermarkService = C2PAWatermarkService.shared
    }
}
