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
        GeometryReader { geometry in
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
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .accessibility(identifier: "back_button")
                            
                            Spacer()
                            
                            Text(item.title)
                                .font(.system(size: min(18, geometry.size.width * 0.045)))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .accessibility(identifier: "options_button")
                        }
                        .padding(.horizontal, min(16, geometry.size.width * 0.04))
                        .padding(.top, geometry.safeAreaInsets.top)
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
                            .frame(height: 44) // Ensure minimum touch target
                            .accessibility(identifier: "progress_slider")
                            
                            // Time indicators and control buttons
                            HStack {
                                // Current time
                                Text(formatTime(progress))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Control buttons
                                HStack(spacing: min(40, geometry.size.width * 0.08)) {
                                    Button(action: {
                                        seekBackward()
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                    }
                                    .accessibility(identifier: "backward_button")
                                    
                                    Button(action: {
                                        togglePlayPause()
                                    }) {
                                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: min(56, geometry.size.width * 0.12)))
                                            .foregroundColor(.white)
                                            .frame(width: 60, height: 60)
                                    }
                                    .accessibility(identifier: "play_pause_button")
                                    
                                    Button(action: {
                                        seekForward()
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                    }
                                    .accessibility(identifier: "forward_button")
                                }
                                
                                Spacer()
                                
                                // Total time
                                Text(formatTime(duration))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            
                            // Volume control
                            if geometry.size.height > 600 { // Only show volume control on taller screens
                                HStack {
                                    Image(systemName: "speaker.fill")
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                    
                                    Slider(value: $volume, in: 0...1) { _ in
                                        player.volume = Float(volume)
                                    }
                                    .accentColor(.white)
                                    .frame(height: 44) // Ensure minimum touch target
                                    .accessibility(identifier: "volume_slider")
                                    
                                    Image(systemName: "speaker.wave.3.fill")
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        .padding(.horizontal, min(16, geometry.size.width * 0.04))
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
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
        Group {
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
            .previewDevice("iPhone 13 Pro")
            
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
            .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 