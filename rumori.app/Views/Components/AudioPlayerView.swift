import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    @StateObject private var playerManager = AudioPlayerManager.shared
    let audioURL: URL
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            Slider(value: $playerManager.currentTime, in: 0...playerManager.duration) { editing in
                if !editing {
                    playerManager.seek(to: playerManager.currentTime)
                }
            }
            .tint(.white)
            
            // Time labels
            HStack {
                Text(formatTime(playerManager.currentTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formatTime(playerManager.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Playback controls
            HStack(spacing: 32) {
                // Rewind button
                Button(action: {
                    playerManager.seek(to: max(0, playerManager.currentTime - 10))
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                
                // Play/Pause button
                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        playerManager.play()
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                
                // Forward button
                Button(action: {
                    playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 10))
                }) {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
            }
            .foregroundColor(.white)
        }
        .onAppear {
            playerManager.load(audioURL)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 
