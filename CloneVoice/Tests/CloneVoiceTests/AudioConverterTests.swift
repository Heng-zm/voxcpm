import Testing
import Foundation
@testable import CloneVoice

@Suite("Audio Converter & Math Tests")
struct AudioConverterTests {
    
    @Test("RMS normalization scales clamped minimum decibel to 0.0")
    func testSilenceNormalization() {
        let normalized = AudioConverter.normalizeDecibels(rms: 0.0)
        #expect(normalized == 0.0)
    }
    
    @Test("RMS normalization scales maximum 0dB to 1.0")
    func testMaxAmplitudeNormalization() {
        let normalized = AudioConverter.normalizeDecibels(rms: 1.0)
        #expect(normalized == 1.0)
    }
    
    @Test("WAV header generator produces valid 44-byte RIFF container")
    func testWAVHeaderGeneration() {
        let sampleDataLength = 48000 * 2 // 1 second of 48kHz 16-bit mono
        let header = AudioConverter.makeWAVHeader(dataLength: sampleDataLength, sampleRate: 48000, channels: 1, bitsPerSample: 16)
        
        #expect(header.count == 44)
        #expect(AudioConverter.isValidWAV(data: header))
    }
    
    @Test("Invalid data is rejected by WAV validator")
    func testInvalidWAV() {
        let randomBytes = Data([0x00, 0x01, 0x02, 0x03])
        #expect(!AudioConverter.isValidWAV(data: randomBytes))
    }
}
