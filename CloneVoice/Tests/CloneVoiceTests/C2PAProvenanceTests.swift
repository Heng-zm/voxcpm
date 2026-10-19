import Testing
import Foundation
@testable import CloneVoice

@Suite("C2PA Content Credentials Provenance Tests")
struct C2PAProvenanceTests {
    
    @Test("Manifest generation creates valid JSON payload")
    func testManifestCreation() throws {
        let service = C2PAWatermarkService()
        let manifestData = try service.createManifest(
            title: "Voice Unit Test",
            profileHash: "abc123hash"
        )
        
        #expect(!manifestData.isEmpty)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(C2PAManifest.self, from: manifestData)
        
        #expect(decoded.title == "Voice Unit Test")
        #expect(decoded.voiceProfileHash == "abc123hash")
        #expect(decoded.engine == "OpenBMB/VoxCPM2")
    }
    
    @Test("Injecting and extracting manifest from WAV round-trips correctly")
    func testWAVInjectionRoundtrip() throws {
        let service = C2PAWatermarkService()
        let baseWAV = AudioConverter.makeWAVHeader(dataLength: 1024) + Data(repeating: 0, count: 1024)
        
        let manifestData = try service.createManifest(
            title: "Roundtrip Test",
            profileHash: "signature-789"
        )
        
        let signedWAV = service.injectManifest(into: baseWAV, manifestData: manifestData)
        #expect(signedWAV.count > baseWAV.count)
        
        let extracted = service.extractManifest(from: signedWAV)
        #expect(extracted != nil)
        #expect(extracted?.title == "Roundtrip Test")
        #expect(extracted?.voiceProfileHash == "signature-789")
    }
}
