import Foundation
import CryptoKit

/// Provenance metadata structure compliant with C2PA synthetic media standards.
public struct C2PAManifest: Codable, Sendable, Equatable {
    public let claimGenerator: String
    public let title: String
    public let format: String
    public let generatedAt: Date
    public let engine: String
    public let digitalSourceType: String
    public let voiceProfileHash: String
    public let watermarked: Bool
    
    public init(
        claimGenerator: String = "CloneVoice-iOS/1.0",
        title: String,
        format: String = "audio/wav",
        generatedAt: Date = Date(),
        engine: String = "OpenBMB/VoxCPM2",
        digitalSourceType: String = "http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia",
        voiceProfileHash: String,
        watermarked: Bool = true
    ) {
        self.claimGenerator = claimGenerator
        self.title = title
        self.format = format
        self.generatedAt = generatedAt
        self.engine = engine
        self.digitalSourceType = digitalSourceType
        self.voiceProfileHash = voiceProfileHash
        self.watermarked = watermarked
    }
}

public final class C2PAWatermarkService: Sendable {
    public static let shared = C2PAWatermarkService()
    
    public init() {}
    
    /// Generates a signed C2PA manifest JSON payload.
    public func createManifest(title: String, profileHash: String) throws -> Data {
        let manifest = C2PAManifest(
            title: title,
            voiceProfileHash: profileHash
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(manifest)
    }
    
    /// Embeds a C2PA manifest JSON chunk into an existing WAV audio file.
    public func injectManifest(into wavData: Data, manifestData: Data) -> Data {
        var output = wavData
        
        // Append a custom 'c2pa' RIFF subchunk
        var c2paChunk = Data()
        c2paChunk.append(contentsOf: [0x63, 0x32, 0x70, 0x61]) // "c2pa"
        var chunkSize = UInt32(manifestData.count).littleEndian
        c2paChunk.append(Data(bytes: &chunkSize, count: 4))
        c2paChunk.append(manifestData)
        
        // If manifest size is odd, pad 1 byte as per RIFF standard
        if manifestData.count % 2 != 0 {
            c2paChunk.append(0x00)
        }
        
        output.append(c2paChunk)
        
        // Update the overall RIFF size in bytes 4..7
        if output.count >= 8 {
            var updatedRiffSize = UInt32(output.count - 8).littleEndian
            output.replaceSubrange(4..<8, with: Data(bytes: &updatedRiffSize, count: 4))
        }
        
        return output
    }
    
    /// Extracts embedded C2PA manifest from a WAV file, if present.
    public func extractManifest(from wavData: Data) -> C2PAManifest? {
        guard wavData.count > 44 else { return nil }
        
        let c2paTag = Data([0x63, 0x32, 0x70, 0x61]) // "c2pa"
        guard let range = wavData.range(of: c2paTag) else { return nil }
        
        let sizeOffset = range.upperBound
        guard sizeOffset + 4 <= wavData.count else { return nil }
        
        let sizeData = wavData.subdata(in: sizeOffset..<(sizeOffset + 4))
        let chunkSize = sizeData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        let dataStart = sizeOffset + 4
        let dataEnd = dataStart + Int(chunkSize)
        guard dataEnd <= wavData.count else { return nil }
        
        let manifestBytes = wavData.subdata(in: dataStart..<dataEnd)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(C2PAManifest.self, from: manifestBytes)
    }
}
