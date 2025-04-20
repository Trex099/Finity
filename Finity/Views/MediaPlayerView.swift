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
        // Reset state in case of retry
        player = nil
        totalDuration = 0
        currentTime = 0
        isPlaying = false
        
        do {
            print("Fetching PlaybackInfo for item: \(item.id)")
            let playbackInfo = try await jellyfinService.fetchPlaybackInfo(itemId: item.id)
            
            // Choose the best media source
            guard let selectedSource = chooseBestMediaSource(from: playbackInfo.mediaSources) else {
                print("Error: No suitable media source found for playback.")
                // TODO: Show error state to user (e.g., set an @State error message)
                return
            }
            
            // Construct the final URL
            guard let url = constructPlaybackURL(from: selectedSource) else {
                print("Error: Could not construct playback URL from selected source.")
                // TODO: Show error state to user
                return
            }
            
            print("Setting up player with URL: \(url)")
            let avPlayer = AVPlayer(url: url)
            
            // Assign player first
            self.player = avPlayer
            
            // Add observers (same as before, but maybe only after player item is ready?)
             addPlayerObservers(player: avPlayer)
            
            // Load duration (can be done after assigning player)
            await loadPlayerDuration(player: avPlayer)
            
            // Start playback automatically
            avPlayer.play()
            isPlaying = true
            scheduleControlsTimer()
            print("Player setup complete, playback started.")
            
        } catch {
            print("Error setting up player: \(error)")
            // TODO: Show error state to user based on the caught error
            // Example: Map URLError codes or Jellyfin API errors to user-friendly messages
        }
    }
    
    // Helper function to choose the best source
    private func chooseBestMediaSource(from sources: [MediaSourceInfo]) -> MediaSourceInfo? {
        // Simple Strategy: Prioritize HLS, then check DirectStream/DirectPlay compatibility
        
        // 1. Prioritize HLS
        if let hlsSource = sources.first(where: { $0.protocol?.lowercased() == "hls" && $0.supportsDirectStream == true }) {
            print("Choosing HLS source.")
            return hlsSource
        }
        
        // 2. Look for compatible DirectStream (basic check)
        // TODO: Add more robust checks based on container/codecs if needed
        if let directStreamSource = sources.first(where: { 
            $0.supportsDirectStream == true && 
            ($0.container?.lowercased() == "mp4" || $0.container?.lowercased() == "mov") // Common iOS compatible containers
        }) {
            print("Choosing DirectStream source (Container: \(directStreamSource.container ?? "N/A"))")
            return directStreamSource
        }
        
        // 3. Look for compatible DirectPlay (basic check)
        if let directPlaySource = sources.first(where: { 
            $0.supportsDirectPlay == true && 
            ($0.container?.lowercased() == "mp4" || $0.container?.lowercased() == "mov") 
        }) {
            print("Choosing DirectPlay source (Container: \(directPlaySource.container ?? "N/A"))")
            return directPlaySource
        }
        
        // 4. Fallback: Maybe the first source if any exists?
        // Or potentially a transcoding source if SupportsTranscoding is true?
        // For now, return nil if no clear best choice found.
        print("No preferred HLS/DirectStream/DirectPlay source found.")
        return sources.first // Fallback to first source if absolutely necessary, might fail.
    }
    
    // Helper function to construct the final URL
    private func constructPlaybackURL(from source: MediaSourceInfo) -> URL? {
        guard let path = source.path else { return nil }
        
        // Check if path is absolute or relative
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            // Assume it's absolute
            return URL(string: path)
        } else {
            // Assume relative, prepend server URL
            guard let serverURL = jellyfinService.serverURL else { return nil }
            
            // Combine server URL and path
            let fullPath = serverURL + path
            
            // --- Authentication for HLS/Streaming --- 
            // Jellyfin often requires the API key for manifests/segments
            if source.protocol?.lowercased() == "hls" || source.isInfiniteStream == true {
                guard let token = jellyfinService.accessToken else { 
                     print("Warning: HLS/Infinite stream may need token, but token is missing.")
                     return URL(string: fullPath) // Return basic URL, might fail
                }
                // Append api_key (check Jellyfin docs if this is correct format)
                var components = URLComponents(string: fullPath)
                var queryItems = components?.queryItems ?? []
                queryItems.append(URLQueryItem(name: "api_key", value: token))
                // Add DeviceId as well, sometimes required
                queryItems.append(URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? ""))
                components?.queryItems = queryItems
                print("Appending api_key/deviceId to HLS URL")
                return components?.url
            } else {
                // For direct play/stream, often no extra token needed in URL if session is authenticated
                return URL(string: fullPath)
            }
        }
    }
    
    // Helper to load duration asynchronously
    private func loadPlayerDuration(player: AVPlayer) async {
         do {
            guard let asset = player.currentItem?.asset else {
                 print("Error: Could not get player item asset to load duration.")
                 return
            }
            let duration = try await asset.load(.duration)
            if duration.seconds.isFinite && !duration.seconds.isNaN {
                 totalDuration = duration.seconds
                 print("Player duration loaded: \(totalDuration) seconds")
            } else {
                print("Warning: Loaded duration is invalid: \(duration.seconds)")
                totalDuration = 0
            }
        } catch {
            print("Error loading player duration: \(error)")
            totalDuration = 0 
        }
    }
    
    // Helper to add player observers
    private func addPlayerObservers(player: AVPlayer) {
         // Play End observer
         NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
             self?.isPlaying = false
         }
         
         // Time observer
         let interval = CMTime(seconds: 1, preferredTimescale: 1)
         timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
             guard let self = self, !self.isSeeking else { return }
             self.currentTime = time.seconds
         }
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