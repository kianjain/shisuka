import SwiftUI
import AVFoundation

struct AudioCropperView: View {
    let audioURL: URL
    @ObservedObject var viewModel: UploadViewModel
    @State private var audioPlayer: AVAudioPlayer?
    @State private var waveformData: [Float] = []
    @State private var startTime: Double = 0
    @State private var endTime: Double = 20
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    @State private var dragStartX: CGFloat = 0
    @State private var isProcessing = false
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(audioURL: URL, viewModel: UploadViewModel) {
        self.audioURL = audioURL
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 12) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("Crop Your Audio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Drag the selection frame to choose a 20-second segment. This helps us optimize storage and ensure smooth playback.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            .padding(.bottom, 60)
            
            // Waveform and Selection
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let padding: CGFloat = 8
                let usableWidth = width - (padding * 2)
                
                ZStack(alignment: .leading) {
                    // Background
                    Color.black
                    
                    // Waveform Container
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: padding)
                        
                        // Waveform
                        HStack(spacing: 2) {
                            ForEach(0..<waveformData.count, id: \.self) { index in
                                let sample = waveformData[index]
                                let normalizedSample = min(max(CGFloat(sample), 0), 1)
                                let barHeight = height * normalizedSample * 0.8
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 2, height: barHeight)
                                    .offset(y: height - barHeight)
                            }
                        }
                        .frame(width: usableWidth)
                        
                        Spacer()
                            .frame(width: padding)
                    }
                    .frame(width: width)
                    .clipped()
                    
                    // Selection
                    if duration > 0 {
                        let selectionWidth = max(0, width * CGFloat((endTime - startTime) / duration))
                        let selectionX = max(0, width * CGFloat(startTime / duration))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            )
                            .frame(width: selectionWidth, height: height)
                            .offset(x: selectionX)
                    }
                    
                    // Playhead
                    if duration > 0 {
                        let playheadX = max(0, width * CGFloat(currentTime / duration))
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: height)
                            .offset(x: playheadX)
                    }
                }
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartX = value.location.x
                            }
                            
                            let dragDistance = value.location.x - dragStartX
                            let timeDelta = Double(dragDistance / width) * duration
                            
                            let newStartTime = max(0, min(duration - (endTime - startTime), startTime + timeDelta))
                            startTime = newStartTime
                            endTime = startTime + 20
                            
                            dragStartX = value.location.x
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 40)
            .padding(.horizontal)
            
            // Time Display
            HStack {
                Text(formatTime(startTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formatTime(endTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Playback Controls
            HStack(spacing: 30) {
                Button(action: {
                    if isPlaying {
                        audioPlayer?.pause()
                    } else {
                        audioPlayer?.currentTime = startTime
                        audioPlayer?.play()
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .overlay(
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geometry.size.width * CGFloat((currentTime - startTime) / (endTime - startTime)))
                                .frame(height: 4),
                            alignment: .leading
                        )
                }
                .frame(height: 4)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Error Message
            if let error = error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Processing Indicator
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            
            Spacer()
            
            // Done Button
            Button(action: {
                isProcessing = true
                Task {
                    do {
                        let croppedURL = try await AudioService.shared.cropAudio(
                            from: audioURL,
                            startTime: startTime,
                            endTime: endTime
                        )
                        await MainActor.run {
                            viewModel.handleCroppedAudio(croppedURL)
                            isProcessing = false
                            dismiss()
                        }
                    } catch {
                        await MainActor.run {
                            self.error = error
                            isProcessing = false
                        }
                    }
                }
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color.black)
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            audioPlayer?.stop()
        }
        .onReceive(timer) { _ in
            if let player = audioPlayer, isPlaying {
                currentTime = player.currentTime
                if currentTime >= endTime {
                    player.pause()
                    isPlaying = false
                    currentTime = startTime
                }
            }
        }
    }
    
    private func loadAudio() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            endTime = min(20, duration)
            generateWaveform()
        } catch {
            self.error = error
        }
    }
    
    private func generateWaveform() {
        guard let audioFile = try? AVAudioFile(forReading: audioURL) else { return }
        
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        try? audioFile.read(into: buffer)
        
        let channelData = buffer.floatChannelData?[0]
        let sampleCount = Int(buffer.frameLength)
        
        let downsampleFactor = max(1, sampleCount / 1000)
        var downsampledData: [Float] = []
        
        for i in stride(from: 0, to: sampleCount, by: downsampleFactor) {
            let start = i
            let end = min(i + downsampleFactor, sampleCount)
            let samples = Array(UnsafeBufferPointer(start: channelData?.advanced(by: start), count: end - start))
            let maxSample = samples.max() ?? 0
            downsampledData.append(maxSample)
        }
        
        waveformData = downsampledData
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct BarWaveformView: View {
    let data: [Float]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<data.count, id: \.self) { index in
                    let sample = data[index]
                    // Ensure sample is between 0 and 1, and calculate height
                    let normalizedSample = min(max(CGFloat(sample), 0), 1)
                    let barHeight = max(1, min(geometry.size.height, geometry.size.height * normalizedSample))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: 2, height: barHeight)
                        .offset(y: (geometry.size.height - barHeight) / 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
} 