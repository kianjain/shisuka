import Foundation
import AVFoundation

class AudioService {
    static let shared = AudioService()
    
    private init() {}
    
    func loadAudio(from url: URL) async throws -> (duration: TimeInterval, waveform: [Float]) {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        
        // Load audio tracks
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = tracks.first else {
            throw NSError(domain: "AudioService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio track found"])
        }
        
        // Load waveform data
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ])
        
        reader.add(output)
        reader.startReading()
        
        var samples: [Float] = []
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)!
            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = Data(count: length)
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &data)
            
            let samplesCount = length / MemoryLayout<Int16>.size
            let int16Samples = data.withUnsafeBytes { $0.bindMemory(to: Int16.self) }
            
            for i in 0..<samplesCount {
                let sample = Float(int16Samples[i]) / Float(Int16.max)
                samples.append(sample)
            }
        }
        
        return (duration.seconds, samples)
    }
    
    func cropAudio(from sourceURL: URL, startTime: TimeInterval, endTime: TimeInterval) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration)
        
        guard startTime >= 0 && endTime <= duration.seconds && startTime < endTime else {
            throw NSError(domain: "AudioService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid time range"])
        }
        
        let composition = AVMutableComposition()
        let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = tracks.first else {
            throw NSError(domain: "AudioService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio track found"])
        }
        
        let timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
        )
        
        try compositionTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .m4a
        
        try await exportSession?.export()
        
        return outputURL
    }
    
    func getAudioDuration(from url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        return try await asset.load(.duration).seconds
    }
} 