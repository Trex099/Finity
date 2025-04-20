import SwiftUI
import AVKit

struct MediaPlayerView: View {
    let item: MediaItem
    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var progress: Double = 0.0
    @State private var duration: Double = 1.0
    @State private var volume: Double = 0.8
    @Environment(\.presentationMode) var presentationMode
    
    // Timer for hiding controls
    @State private var controlsTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Video player
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                    resetControlsTimer()
                }
            
            // Floating controls overlay
            if showControls {
                // Top bar with back button and title
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Progress bar
                        Slider(value: $progress, in: 0...duration) { editing in
                            if !editing {
                                player.seek(to: CMTime(seconds: progress, preferredTimescale: 600))
                            }
                        }
                        .accentColor(.white)
                        
                        // Time indicators and control buttons
                        HStack {
                            // Current time
                            Text(formatTime(progress))
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Control buttons
                            HStack(spacing: 40) {
                                Button(action: {
                                    seekBackward()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    togglePlayPause()
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 56))
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    seekForward()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            // Total time
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        // Volume control
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.white)
                            
                            Slider(value: $volume, in: 0...1) { _ in
                                player.volume = Float(volume)
                            }
                            .accentColor(.white)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            setupPlayer()
            startControlsTimer()
        }
        .onDisappear {
            player.pause()
            controlsTimer?.invalidate()
        }
    }
    
    // Helper functions
    private func setupPlayer() {
        // In a real app, you would use the actual video URL from Jellyfin
        guard let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Get duration
        let durationCMTime = playerItem.asset.duration
        duration = CMTimeGetSeconds(durationCMTime)
        
        // Set up time observer
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: DispatchQueue.main) { time in
            progress = CMTimeGetSeconds(time)
        }
        
        // Set volume
        player.volume = Float(volume)
        
        // Auto-play
        player.play()
        isPlaying = true
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        resetControlsTimer()
    }
    
    private func seekForward() {
        let newTime = min(progress + 10, duration)
        progress = newTime
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        resetControlsTimer()
    }
    
    private func seekBackward() {
        let newTime = max(progress - 10, 0)
        progress = newTime
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        resetControlsTimer()
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let hours = Int(timeInSeconds) / 3600
        let minutes = (Int(timeInSeconds) % 3600) / 60
        let seconds = Int(timeInSeconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation {
                if isPlaying {
                    showControls = false
                }
            }
        }
    }
    
    private func resetControlsTimer() {
        startControlsTimer()
    }
}

struct MediaPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MediaPlayerView(item: MediaItem(
            id: "1",
            title: "Inception",
            posterPath: "inception",
            type: .movie,
            year: "2010",
            rating: 8.8,
            overview: "A thief who steals corporate secrets through dream-sharing technology."
        ))
        .preferredColorScheme(.dark)
    }
} 