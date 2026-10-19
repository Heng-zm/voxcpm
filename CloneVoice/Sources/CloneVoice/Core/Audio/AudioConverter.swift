import Foundation

/// Pure utility functions for audio math, WAV formatting, and dynamic level scaling.
public enum AudioConverter: Sendable {
    
    /// Normalizes raw RMS amplitude to a perceptually linear [0.0...1.0] scale using decibels.
    public static func normalizeDecibels(rms: Float, minDB: Float = -60.0, maxDB: Float = 0.0) -> Float {
        guard rms > 0.00001 else { return 0.0 }
        let db = 20.0 * log10(rms)
        let clamped = max(minDB, min(maxDB, db))
        return (clamped - minDB) / (maxDB - minDB)
    }
    
    /// Constructs a standard 44-byte RIFF/WAV header for 16-bit Linear PCM audio.
    public static func makeWAVHeader(
        dataLength: Int,
        sampleRate: Int = 48000,
        channels: Int = 1,
        bitsPerSample: Int = 16
    ) -> Data {
        var header = Data()
        
        let byteRate = sampleRate * channels * (bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let chunkSize = 36 + dataLength
        
        // RIFF chunk descriptor
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        header.append(UInt32(chunkSize).littleEndianData)
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        
        // "fmt " sub-chunk
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        header.append(UInt32(16).littleEndianData)          // Subchunk1Size for PCM
        header.append(UInt16(1).littleEndianData)           // AudioFormat 1 = PCM
        header.append(UInt16(channels).littleEndianData)
        header.append(UInt32(sampleRate).littleEndianData)
        header.append(UInt32(byteRate).littleEndianData)
        header.append(UInt16(blockAlign).littleEndianData)
        header.append(UInt16(bitsPerSample).littleEndianData)
        
        // "data" sub-chunk
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        header.append(UInt32(dataLength).littleEndianData)
        
        return header
    }
    
    /// Inspects binary data to ensure it begins with a valid RIFF/WAVE header.
    public static func isValidWAV(data: Data) -> Bool {
        guard data.count >= 44 else { return false }
        let riff = data.prefix(4)
        let wave = data.subdata(in: 8..<12)
        return riff == Data([0x52, 0x49, 0x46, 0x46]) && wave == Data([0x57, 0x41, 0x56, 0x45])
    }
    
    /// Inspects audio data and ensures it is wrapped in a structurally correct 44-byte RIFF/WAV header.
    /// Strips any non-standard trailing chunks (such as proprietary c2pa blocks) that crash CoreAudio / AVAudioPlayer.
    public static func ensureValidWAV(
        data: Data,
        sampleRate: Int = 48000,
        channels: Int = 1,
        bitsPerSample: Int = 16
    ) -> Data {
        return extractCleanWAV(from: data, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample)
    }
    
    /// Extracts pure PCM audio data and returns a canonical 44-byte RIFF/WAV container.
    /// Strips any non-standard trailing chunks (such as proprietary c2pa blocks) that crash CoreAudio / AVAudioPlayer.
    public static func extractCleanWAV(
        from data: Data,
        sampleRate: Int = 48000,
        channels: Int = 1,
        bitsPerSample: Int = 16
    ) -> Data {
        guard data.count >= 44 && isValidWAV(data: data) else {
            return makeWAVHeader(dataLength: data.count, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample) + data
        }
        
        let dataTag = Data([0x64, 0x61, 0x74, 0x61]) // "data"
        let searchRange = 12..<min(data.count, 128)
        
        guard let range = data.range(of: dataTag, in: searchRange) else {
            let pcm = data.dropFirst(44)
            return makeWAVHeader(dataLength: pcm.count, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample) + pcm
        }
        
        let sizeOffset = range.upperBound
        guard sizeOffset + 4 <= data.count else {
            let pcm = data.dropFirst(44)
            return makeWAVHeader(dataLength: pcm.count, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample) + pcm
        }
        
        let pcmStart = sizeOffset + 4
        let c2paTag = Data([0x63, 0x32, 0x70, 0x61]) // "c2pa"
        let pcmEnd: Int
        if let c2paRange = data.range(of: c2paTag, in: pcmStart..<data.count) {
            pcmEnd = c2paRange.lowerBound
        } else {
            pcmEnd = data.count
        }
        
        let pcmBytes = data.subdata(in: pcmStart..<pcmEnd)
        let header = makeWAVHeader(dataLength: pcmBytes.count, sampleRate: sampleRate, channels: channels, bitsPerSample: bitsPerSample)
        return header + pcmBytes
    }
    
    /// Generates a valid 48kHz 16-bit mono WAV audio sample with rich vocal harmonics and gentle vibrato.
    public static func generateStarterSampleWAV(
        durationSeconds: Double = 3.0,
        sampleRate: Int = 48000
    ) -> Data {
        let totalSamples = Int(durationSeconds * Double(sampleRate))
        var pcmData = Data(capacity: totalSamples * 2)
        
        let f0: Double = 175.0 // Natural human vocal pitch
        let f1: Double = 530.0 // Formant F1 (e.g. 'e' vowel)
        let f2: Double = 1840.0 // Formant F2
        
        var phase: Double = 0.0
        var f1Phase: Double = 0.0
        var f2Phase: Double = 0.0
        
        let attackSamples = Int(0.05 * Double(sampleRate))
        let decaySamples = Int(0.10 * Double(sampleRate))
        
        for i in 0..<totalSamples {
            // Subtle 5.2 Hz vibrato
            let vibrato = 1.0 + 0.018 * sin(2.0 * Double.pi * 5.2 * (Double(i) / Double(sampleRate)))
            let currentF0 = f0 * vibrato
            let phaseInc = (2.0 * Double.pi * currentF0) / Double(sampleRate)
            let f1Inc = (2.0 * Double.pi * f1) / Double(sampleRate)
            let f2Inc = (2.0 * Double.pi * f2) / Double(sampleRate)
            
            // Glottal excitation
            let h1 = sin(phase)
            let h2 = 0.5 * sin(2.0 * phase)
            let h3 = 0.25 * sin(3.0 * phase)
            let glottal = (h1 + h2 + h3) * 0.65
            
            // Vocal tract formant resonance
            let formant = (sin(f1Phase) * 0.45) + (sin(f2Phase) * 0.25)
            
            // Smooth attack and decay envelope
            var envelope: Double = 1.0
            if i < attackSamples {
                envelope = Double(i) / Double(attackSamples)
            } else if i > (totalSamples - decaySamples) {
                envelope = Double(totalSamples - i) / Double(decaySamples)
            }
            
            let sampleVal = max(-0.95, min(0.95, (glottal + formant * 0.35) * envelope * 0.75))
            let int16Sample = Int16(sampleVal * 32767.0)
            
            withUnsafeBytes(of: int16Sample.littleEndian) { raw in
                pcmData.append(contentsOf: raw)
            }
            
            phase += phaseInc
            if phase > 2.0 * Double.pi { phase -= 2.0 * Double.pi }
            f1Phase += f1Inc
            if f1Phase > 2.0 * Double.pi { f1Phase -= 2.0 * Double.pi }
            f2Phase += f2Inc
            if f2Phase > 2.0 * Double.pi { f2Phase -= 2.0 * Double.pi }
        }
        
        let header = makeWAVHeader(dataLength: pcmData.count, sampleRate: sampleRate, channels: 1, bitsPerSample: 16)
        return header + pcmData
    }
}

private extension UInt16 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
}

private extension UInt32 {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}
