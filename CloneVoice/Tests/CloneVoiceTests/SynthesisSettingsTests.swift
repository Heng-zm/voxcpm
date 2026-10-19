import Testing
import Foundation
@testable import CloneVoice

@Suite("Synthesis Settings Tests")
struct SynthesisSettingsTests {
    
    @Test("Settings parameters clamp out-of-range values safely")
    func testBoundaryClamping() {
        let extremeSettings = SynthesisSettings(
            cfgScale: 10.0,
            timesteps: 100,
            speedMultiplier: 5.0
        )
        
        #expect(extremeSettings.cfgScale == 5.0)
        #expect(extremeSettings.timesteps == 30)
        #expect(extremeSettings.speedMultiplier == 2.0)
    }
    
    @Test("Standard presets contain expected production defaults")
    func testStandardPreset() {
        let standard = SynthesisSettings.standard
        #expect(standard.cfgScale == 2.0)
        #expect(standard.timesteps == 10)
        #expect(standard.watermarkEnabled == true)
        #expect(standard.zeroRetention == true)
    }
    
    @Test("JSON roundtrip serialization preserves all fields")
    func testSerializationRoundtrip() throws {
        let original = SynthesisSettings(
            cfgScale: 2.8,
            timesteps: 18,
            emotionInstruction: "Reflective and resonant",
            speedMultiplier: 1.1,
            watermarkEnabled: true,
            zeroRetention: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SynthesisSettings.self, from: data)
        
        #expect(decoded == original)
    }
}
