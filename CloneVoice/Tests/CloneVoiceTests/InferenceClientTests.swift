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
    
    @Test("AppEnvironment initializes with Render endpoint by default")
    @MainActor
    func testAppEnvironmentDefaultURL() {
        let env = AppEnvironment(inMemory: true)
        #expect(env.inferenceClient.baseURL.absoluteString == "https://voxcpm-xsp6.onrender.com")
    }
}
