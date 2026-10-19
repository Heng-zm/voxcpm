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
    
    @Test("ensureValidWAV wraps raw PCM data with valid 44-byte header")
    func testEnsureValidWAVWithRawPCM() {
        let pcm = Data(repeating: 0x55, count: 4800)
        let wav = AudioConverter.ensureValidWAV(data: pcm)
        
        #expect(wav.count == 44 + 4800)
        #expect(AudioConverter.isValidWAV(data: wav))
    }
    
    @Test("ensureValidWAV repairs zero-length data subchunk header")
    func testEnsureValidWAVRepairZeroHeader() {
        // Create broken header with 0 data length followed by actual PCM samples
        let brokenHeader = AudioConverter.makeWAVHeader(dataLength: 0)
        let pcm = Data(repeating: 0x7F, count: 9600)
        let brokenWAV = brokenHeader + pcm
        
        let repaired = AudioConverter.ensureValidWAV(data: brokenWAV)
        #expect(repaired.count == 44 + 9600)
        
        // Check subchunk2Size at offset 40..<44
        let subchunkSize = repaired.subdata(in: 40..<44).withUnsafeBytes { $0.load(as: UInt32.self) }
        #expect(subchunkSize == 9600)
    }
    
    @Test("generateStarterSampleWAV produces complete 3-second playable WAV")
    func testGenerateStarterSampleWAV() {
        let starter = AudioConverter.generateStarterSampleWAV(durationSeconds: 1.0)
        #expect(starter.count == 44 + (48000 * 2))
        #expect(AudioConverter.isValidWAV(data: starter))
    }
    
    @Test("extractCleanWAV strips trailing non-standard chunks and returns pure WAV")
    func testExtractCleanWAVStripsTrailingChunks() {
        let pcm = Data(repeating: 0x2A, count: 4800)
        let clean = AudioConverter.makeWAVHeader(dataLength: pcm.count) + pcm
        let dirty = clean + Data([0x63, 0x32, 0x70, 0x61, 0x10, 0x00, 0x00, 0x00]) + Data(repeating: 0x99, count: 16)
        
        let extracted = AudioConverter.extractCleanWAV(from: dirty)
        #expect(extracted.count == 44 + 4800)
        #expect(AudioConverter.isValidWAV(data: extracted))
    }
}
