import SwiftUI
import AVKit
import Combine

// Main View holding the player and custom controls
struct MediaPlayerView: View {
    let item: MediaItem
    @EnvironmentObject var jellyfinService: JellyfinService
    @Environment(\.dismiss) var dismiss
    
    // Player state
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var controlsTimer: Timer? = nil
    @State private var currentTime: Double = 0
    @State private var totalDuration: Double = 0
    @State private var timeObserverToken: Any? = nil
    @State private var isSeeking = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Video Player Representable
            if let player = player {
                VideoPlayerViewControllerRepresentable(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        toggleControlsVisibility()
                    }
            } else {
                // Loading indicator or error message
                ProgressView()
                    .scaleEffect(2)
                    .task { await setupPlayer() } // Use .task for async setup
            }
            
            // Custom Controls Overlay
            if showControls && player != nil {
                CustomPlayerControlsView(
                    itemTitle: item.name,
                    isPlaying: $isPlaying,
                    currentTime: $currentTime,
                    totalDuration: $totalDuration,
                    isSeeking: $isSeeking,
                    onPlayPause: togglePlayPause,
                    onSeek: seek(to:),
                    onClose: { dismiss() }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .statusBar(hidden: true)
        .onDisappear(perform: cleanupPlayer)
        // Listen for player status changes if needed
        // .onReceive(player.publisher(for: \\.status)) { status in ... }
    }
    
    // MARK: - Player Setup & Cleanup
    
    private func setupPlayer() async {
        guard let url = jellyfinService.getVideoStreamURL(itemId: item.id) else {
            print("Error: Could not get video stream URL for \(item.id)")
            // TODO: Show error state to user
            return
        }
        print("Setting up player with URL: \(url)")
        let avPlayer = AVPlayer(url: url)
        
        // Assign player first
        self.player = avPlayer
        
        // Listen for player item status changes (No [weak self])
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem, queue: .main) { _ in
            // Since MediaPlayerView is a struct, direct mutation is fine here.
            isPlaying = false
        }
        
        // Get total duration asynchronously
        do {
            let duration = try await avPlayer.load(.duration)
            // Ensure duration is valid before setting
            if duration.seconds.isFinite && !duration.seconds.isNaN {
                 totalDuration = duration.seconds
                 print("Player duration loaded: \(totalDuration) seconds")
            } else {
                print("Warning: Loaded duration is invalid: \(duration.seconds)")
                totalDuration = 0 // Set a default or handle error
            }
        } catch {
            print("Error loading player duration: \(error)")
            totalDuration = 0 // Set a default or handle error
            // TODO: Potentially show error state to user
        }
        
        // Setup time observer (No [weak self], self is implicitly captured)
        let interval = CMTime(seconds: 1, preferredTimescale: 1)
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            // Guard against mutations while seeking
            guard !isSeeking else { return }
            currentTime = time.seconds
        }
        
        // Start playback automatically
        // Ensure player setup (like duration loading) is somewhat complete before playing
        // Although AVPlayer usually handles this gracefully.
        avPlayer.play()
        isPlaying = true
        scheduleControlsTimer()
        print("Player setup complete, playback started.")
    }
    
    private func cleanupPlayer() {
        player?.pause()
        if let observer = timeObserverToken {
            player?.removeTimeObserver(observer)
            timeObserverToken = nil
        }
        controlsTimer?.invalidate()
        controlsTimer = nil
        player = nil
        print("MediaPlayerView disappeared, player cleaned up.")
    }
    
    // MARK: - Controls Logic
    
    private func toggleControlsVisibility() {
        withAnimation {
            showControls.toggle()
        }
        if showControls {
            scheduleControlsTimer() // Reschedule timer when controls are shown
        } else {
            controlsTimer?.invalidate() // Invalidate timer when controls are hidden manually
        }
    }
    
    private func scheduleControlsTimer() {
        controlsTimer?.invalidate() // Invalidate existing timer
        // Hide controls after 4 seconds if playing
        if isPlaying {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                if isPlaying { // Only hide if still playing
                    withAnimation {
                        showControls = false
                    }
                }
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            controlsTimer?.invalidate() // Keep controls visible when paused
        } else {
            player.play()
            scheduleControlsTimer() // Start timer when playing
        }
        isPlaying.toggle()
    }
    
    private func seek(to time: Double) {
        guard let player = player else { return }
        let targetTime = CMTime(seconds: time, preferredTimescale: 600) // High precision timescale
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            // No [weak self], self is implicitly captured for struct
            isSeeking = false // Re-enable time updates after seek finishes
            if finished {
                // Optionally resume playback if it was playing before seek started
                if isPlaying {
                    player.play() // Directly use captured player
                }
            }
            // Keep controls visible after seeking
            showControls = true
            scheduleControlsTimer()
        }
    }
}

// MARK: - UIViewControllerRepresentable for AVPlayerViewController

struct VideoPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // Hide default controls
        controller.videoGravity = .resizeAspect // Or .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update the player if it changes (though less common with @State in parent)
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}

// MARK: - Custom Player Controls View

struct CustomPlayerControlsView: View {
    let itemTitle: String
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    @Binding var totalDuration: Double
    @Binding var isSeeking: Bool
    
    var onPlayPause: () -> Void
    var onSeek: (Double) -> Void // Called when scrubbing finishes
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed Background for controls
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Top Bar (Close Button, Title)
                HStack {
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Text(itemTitle)
                        .foregroundColor(.white)
                        .font(.headline)
                        .lineLimit(1)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 12)
                
                Spacer() // Push controls to center and bottom
                
                // Middle Controls (Seek, Play/Pause, Seek)
                HStack(spacing: 50) { // Adjust spacing as needed
                    // Rewind 10s Button
                    Button {
                        let seekTime = max(currentTime - 10, 0) // Prevent seeking before 0
                        onSeek(seekTime)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    .accessibility(identifier: "seek_backward_10")
                    
                    // Play/Pause Button
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .accessibility(identifier: "play_pause_button")
                    
                    // Forward 10s Button
                    Button {
                        let seekTime = min(currentTime + 10, totalDuration) // Prevent seeking beyond duration
                        onSeek(seekTime)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    .accessibility(identifier: "seek_forward_10")
                }
                .padding(.bottom, 30) // Space above slider

                Spacer()

                // Bottom Bar (Slider, Time)
                VStack(spacing: 5) {
                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(totalDuration))
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    
                    Slider(value: $currentTime, in: 0...max(totalDuration, 1), onEditingChanged: sliderEditingChanged)
                        .accentColor(.red) // Netflix red
                }
                .padding(.horizontal)
                .padding(.bottom, 20) // Padding from bottom edge
            }
            .padding(.vertical)
        }
    }
    
    private func sliderEditingChanged(editingStarted: Bool) {
        isSeeking = editingStarted
        if !editingStarted {
            // User finished scrubbing, perform the actual seek
            onSeek(currentTime)
        }
    }
    
    // Helper to format time (e.g., 1:05:32 or 55:10)
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN, !time.isInfinite, time >= 0 else {
            return "--:--"
        }
        
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// Preview Provider (requires adjustments)
/*
struct MediaPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        // Need a mock item and service
        // let mockItem = MediaItem(...) 
        // let mockService = JellyfinService()
        // MediaPlayerView(item: mockItem).environmentObject(mockService)
    }
}
*/ 