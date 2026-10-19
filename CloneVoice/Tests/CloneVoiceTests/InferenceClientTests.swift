import Testing
import Foundation
@testable import CloneVoice

@Suite("Inference Client Tests")
struct InferenceClientTests {
    
    @Test("Inference client defaults to production Render endpoint")
    func testDefaultRenderEndpoint() {
        let client = VoxCPMInferenceClient()
        #expect(client.baseURL.absoluteString == "https://voxcpm-xsp6.onrender.com")
    }
    
    @Test("Inference client accepts custom base URL")
    func testCustomBaseURL() {
        let customURL = URL(string: "https://custom-tts.example.com")!
        let client = VoxCPMInferenceClient(baseURL: customURL)
        #expect(client.baseURL == customURL)
    }
    
    @Test("AppEnvironment defaults to On-Device Apple GPU execution target")
    @MainActor
    func testAppEnvironmentDefaultExecutionTarget() {
        let env = AppEnvironment(inMemory: true)
        #expect(env.executionTarget == .onDeviceGPU)
    }
    
    @Test("OnDeviceMetalInferenceService reports ready hardware status")
    func testOnDeviceMetalServiceStatus() async throws {
        let service = OnDeviceMetalInferenceService()
        let status = try await service.checkHealth()
        switch status {
        case .ready(let gpuModel, let vram):
            #expect(!gpuModel.isEmpty)
            #expect(vram > 0)
        default:
            Issue.record("Expected on-device service to report ready status")
        }
    }
}
