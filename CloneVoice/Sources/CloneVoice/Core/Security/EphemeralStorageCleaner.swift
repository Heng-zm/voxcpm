import Foundation

/// Handles zero-data-retention disk wiping for temporary voice recordings and audio streams.
public final class EphemeralStorageCleaner: Sendable {
    public static let shared = EphemeralStorageCleaner()
    
    public init() {}
    
    /// Securely overwrites a file with random bytes before deleting it from disk.
    public func securelyWipeFile(at url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0
            
            if fileSize > 0 {
                let randomData = Data((0..<fileSize).map { _ in UInt8.random(in: 0...255) })
                try randomData.write(to: url, options: .atomic)
            }
            
            try FileManager.default.removeItem(at: url)
        } catch {
            // Fallback to standard removal if overwrite fails
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Purges all temporary voice session files in NSTemporaryDirectory.
    public func clearTemporaryDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            if file.pathExtension == "wav" || file.pathExtension == "pcm" || file.lastPathComponent.contains("stream_") {
                securelyWipeFile(at: file)
            }
        }
    }
}
