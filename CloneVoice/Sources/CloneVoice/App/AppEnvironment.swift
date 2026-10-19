import Foundation
import SwiftData
import SwiftUI

public enum InferenceExecutionTarget: String, CaseIterable, Identifiable, Sendable {
    case onDeviceGPU = "On-Device Apple GPU"
    case remoteCloud = "Remote Cloud Server"
    
    public var id: String { rawValue }
}

/// Central dependency injection environment for Clone Voice.
@MainActor
@Observable
public final class AppEnvironment {
    public let profileRepository: any VoiceProfileRepositoryProtocol
    public let utteranceRepository: any UtteranceRepositoryProtocol
    public let audioEngine: AudioEngineActor
    public let streamPlayer: AudioStreamPlayer
    
    public let onDeviceService: OnDeviceMetalInferenceService
    public let inferenceClient: VoxCPMInferenceClient
    
    public var executionTarget: InferenceExecutionTarget {
        didSet {
            UserDefaults.standard.set(executionTarget.rawValue, forKey: "inference_execution_target")
        }
    }
    
    /// The currently active inference service based on user preference (Defaults to On-Device Apple GPU).
    public var activeInferenceService: any VoiceInferenceServiceProtocol {
        switch executionTarget {
        case .onDeviceGPU:
            return onDeviceService
        case .remoteCloud:
            return inferenceClient
        }
    }
    
    public let biometricAuth: BiometricAuthService
    public let watermarkService: C2PAWatermarkService
    
    public init(
        inMemory: Bool = false,
        backendURL: URL? = nil,
        defaultTarget: InferenceExecutionTarget = .onDeviceGPU
    ) {
        let container = SwiftDataContainer(inMemory: inMemory).container
        self.profileRepository = SwiftDataVoiceProfileRepository(container: container)
        self.utteranceRepository = SwiftDataUtteranceRepository(container: container)
        self.audioEngine = AudioEngineActor()
        self.streamPlayer = AudioStreamPlayer()
        
        let storedTargetRaw = UserDefaults.standard.string(forKey: "inference_execution_target")
        self.executionTarget = storedTargetRaw.flatMap(InferenceExecutionTarget.init(rawValue:)) ?? defaultTarget
        
        self.onDeviceService = OnDeviceMetalInferenceService()
        
        let storedURLString = UserDefaults.standard.string(forKey: "custom_backend_url")
        let effectiveURL = backendURL 
            ?? storedURLString.flatMap(URL.init(string:)) 
            ?? URL(string: "https://voxcpm-xsp6.onrender.com")!
            
        self.inferenceClient = VoxCPMInferenceClient(baseURL: effectiveURL)
        self.biometricAuth = BiometricAuthService.shared
        self.watermarkService = C2PAWatermarkService.shared
    }
}
