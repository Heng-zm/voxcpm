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
