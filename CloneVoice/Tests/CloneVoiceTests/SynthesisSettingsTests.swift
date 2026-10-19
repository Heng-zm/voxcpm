import Testing
import Foundation
@testable import CloneVoice

@Suite("Synthesis Settings Tests")
struct SynthesisSettingsTests {
    
    @Test("Settings parameters clamp out-of-range values safely")
    func testBoundaryClamping() {
        let extremeSettings = SynthesisSettings(
            cfgValue: 10.0,
            inferenceTimesteps: 100,
            denoise: true,
            seed: 42
        )
        
        #expect(extremeSettings.cfgValue == 3.0)
        #expect(extremeSettings.inferenceTimesteps == 30)
        #expect(extremeSettings.denoise == true)
        #expect(extremeSettings.seed == 42)
    }
    
    @Test("Standard presets contain expected verified VoxCPM2 production defaults")
    func testStandardPreset() {
        let standard = SynthesisSettings.standard
        #expect(standard.cfgValue == 2.0)
        #expect(standard.inferenceTimesteps == 10)
        #expect(standard.denoise == true)
        #expect(standard.zeroRetention == true)
    }
    
    @Test("JSON roundtrip serialization preserves all verified VoxCPM2 fields")
    func testSerializationRoundtrip() throws {
        let original = SynthesisSettings(
            cfgValue: 2.4,
            inferenceTimesteps: 16,
            denoise: true,
            seed: 12345,
            zeroRetention: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SynthesisSettings.self, from: data)
        
        #expect(decoded == original)
    }
}
