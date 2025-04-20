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
    @State private var error: String? = nil
    @State private var isLoading = false
    @State private var currentItemId: String? = nil
    
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
        guard item.id != nil else {
            print("Error setting up player: Item has no ID")
            self.error = "Error: Unable to play item (missing ID)"
            return
        }
        
        currentItemId = item.id
        
        // Show loading indicator
        isLoading = true
        
        // Fetch playback info from Jellyfin
        Task {
            do {
                // Get playback info
                let itemId = item.id!
                print("Fetching PlaybackInfo for item: \(itemId)")
                
                if let playbackInfoResponse = try await jellyfinService.getPlaybackInfo(for: itemId) {
                    print("Successfully fetched PlaybackInfo with \(playbackInfoResponse.mediaSources?.count ?? 0) media sources.")
                    
                    // Choose the best media source
                    if let bestSource = chooseBestMediaSource(from: playbackInfoResponse.mediaSources) {
                        // Construct playback URL
                        if let mediaUrl = self.constructPlaybackURL(source: bestSource, itemId: itemId) {
                            print("Setting up player with URL: \(mediaUrl.absoluteString)")
                            setupAVPlayer(with: mediaUrl)
                            startPlaybackSession(itemId: itemId)
                            return
                        }
                    } else {
                        print("No preferred HLS/DirectStream/DirectPlay source found.")
                        
                        // Fallback: Attempt to construct HLS URL manually
                        print("Fallback: Attempting to construct HLS URL manually.")
                        if let manualHLSUrl = constructManualHLSURL(itemId: itemId) {
                            print("Setting up player with URL: \(manualHLSUrl.absoluteString)")
                            setupAVPlayer(with: manualHLSUrl)
                            startPlaybackSession(itemId: itemId)
                            return
                        }
                    }
                    
                    // If we get here, we couldn't find a valid URL
                    self.error = "Error: No compatible playback source found"
                    isLoading = false
                } else {
                    self.error = "Error: Could not get playback information"
                    isLoading = false
                }
            } catch let error as JellyfinError {
                print("Error setting up player: \(error.localizedDescription)")
                self.error = "Error: \(error.localizedDescription)"
                isLoading = false
            } catch {
                print("Error setting up player: \(error.localizedDescription)")
                self.error = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // Helper function to choose the best source
    private func chooseBestMediaSource(from sources: [MediaSourceInfo]) -> MediaSourceInfo? {
        print("Evaluating \(sources.count) media sources...")
        for source in sources {
            print("  - Source ID: \(source.id ?? "N/A"), Protocol: \(source.protocol ?? "N/A"), Path: \(source.path ?? "N/A"), Container: \(source.container ?? "N/A"), DirectPlay: \(source.supportsDirectPlay ?? false), DirectStream: \(source.supportsDirectStream ?? false)")
        }
        
        // 1. Prioritize HLS (protocol Hls, likely direct streamable)
        if let hlsSource = sources.first(where: { 
            ($0.protocol?.caseInsensitiveCompare("hls") == .orderedSame) && 
            $0.supportsDirectStream == true 
        }) {
            print("Choosing HLS source.")
            return hlsSource
        }
        
        // 2. Look for compatible HTTP DirectStream
        let compatibleContainers = ["mp4", "mov", "m4v"] // Add other known good containers
        if let directStreamSource = sources.first(where: { 
            ($0.protocol?.caseInsensitiveCompare("http") == .orderedSame || $0.protocol?.caseInsensitiveCompare("https") == .orderedSame) &&
            $0.supportsDirectStream == true && 
            compatibleContainers.contains($0.container?.lowercased() ?? "") &&
            (($0.path?.hasPrefix("/") ?? false) || ($0.path?.hasPrefix("http") ?? false)) // Ensure path is relative web path or absolute web URL
        }) {
            print("Choosing DirectStream source (Container: \(directStreamSource.container ?? "N/A"))")
            return directStreamSource
        }
        
        // 3. Look for compatible HTTP DirectPlay
        if let directPlaySource = sources.first(where: { 
            ($0.protocol?.caseInsensitiveCompare("http") == .orderedSame || $0.protocol?.caseInsensitiveCompare("https") == .orderedSame) &&
            $0.supportsDirectPlay == true && 
            compatibleContainers.contains($0.container?.lowercased() ?? "") &&
            (($0.path?.hasPrefix("/") ?? false) || ($0.path?.hasPrefix("http") ?? false)) // Ensure path is relative web path or absolute web URL
        }) {
            print("Choosing DirectPlay source (Container: \(directPlaySource.container ?? "N/A"))")
            return directPlaySource
        }
        
        // 4. No suitable HLS or HTTP source found
        print("No preferred HLS/DirectStream/DirectPlay source found.")
        return nil // Return nil, let setupPlayer handle fallback
    }
    
    // Helper function to construct the final URL
    private func constructPlaybackURL(from source: MediaSourceInfo, itemId: String) -> URL? {
        guard let path = source.path else { 
            print("Error: MediaSourceInfo has no path.")
            return nil 
        }
        
        // Check if path is absolute HTTP/HTTPS URL
        if path.lowercased().hasPrefix("http://") || path.lowercased().hasPrefix("https://") {
            print("Constructing URL from absolute path: \(path)")
            return URL(string: path)
        } 
        // Check if path is a relative web path (starts with /)
        else if path.hasPrefix("/") {
             // Assume relative, prepend server URL
            guard let serverURL = jellyfinService.serverURL else { 
                print("Error: Cannot construct relative URL, missing serverURL.")
                return nil 
            }
            let fullPath = serverURL + path
             print("Constructing URL from relative path: \(fullPath)")
            
            // --- Authentication for HLS/Streaming --- 
            if source.protocol?.lowercased() == "hls" || source.isInfiniteStream == true {
                guard let token = jellyfinService.accessToken else { 
                     print("Warning: HLS/Infinite stream may need token, but token is missing.")
                     return URL(string: fullPath)
                }
                var components = URLComponents(string: fullPath)
                var queryItems = components?.queryItems ?? []
                queryItems.append(URLQueryItem(name: "api_key", value: token))
                queryItems.append(URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? ""))
                components?.queryItems = queryItems
                print("Appending api_key/deviceId to HLS URL")
                return components?.url
            } else {
                // For direct play/stream over HTTP/HTTPS with relative path
                return URL(string: fullPath)
            }
        } 
        // If path is not absolute HTTP and not relative starting with /, treat as invalid (e.g., file path)
        else {
             print("Error: MediaSourceInfo path '\(path)' is not a recognized web path or URL.")
             return nil
        }
    }
    
    // New helper to manually construct an HLS URL as a fallback
    private func constructManualHLSURL(itemId: String) -> URL? {
        guard let serverURL = jellyfinService.serverURL, 
              let token = jellyfinService.accessToken else { 
            print("Error constructing manual HLS URL: Missing serverURL or accessToken.")
            return nil
        }
        
        // Standard transcoding endpoint (more reliable than /master.m3u8)
        let path = "/Videos/\(itemId)/stream"
        let fullPath = serverURL + path
        
        var components = URLComponents(string: fullPath)
        var queryItems = [URLQueryItem]()
        
        // Authentication params
        queryItems.append(URLQueryItem(name: "api_key", value: token))
        queryItems.append(URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? ""))
        
        // Required transcoding parameters for Jellyfin
        queryItems.append(URLQueryItem(name: "container", value: "ts"))            // Transport stream container
        queryItems.append(URLQueryItem(name: "videoCodec", value: "h264"))         // Video codec
        queryItems.append(URLQueryItem(name: "audioCodec", value: "aac"))          // Audio codec
        queryItems.append(URLQueryItem(name: "transcodingContainer", value: "ts")) // Transcoding container
        queryItems.append(URLQueryItem(name: "maxWidth", value: "1920"))           // Max width
        queryItems.append(URLQueryItem(name: "maxHeight", value: "1080"))          // Max height
        queryItems.append(URLQueryItem(name: "videoBitRate", value: "8000000"))    // Video bitrate
        queryItems.append(URLQueryItem(name: "audioBitRate", value: "192000"))     // Audio bitrate
        queryItems.append(URLQueryItem(name: "maxAudioChannels", value: "2"))      // Audio channels
        queryItems.append(URLQueryItem(name: "startTimeTicks", value: "0"))        // Start at beginning
        queryItems.append(URLQueryItem(name: "subtitleMethod", value: "Encode"))   // Subtitle method
        queryItems.append(URLQueryItem(name: "enableDirectPlay", value: "false"))  // Force transcoding
        queryItems.append(URLQueryItem(name: "enableDirectStream", value: "false"))// Force transcoding
        queryItems.append(URLQueryItem(name: "TranscodingMaxAudioChannels", value: "2"))
        
        // Streaming format parameters (HLS)
        queryItems.append(URLQueryItem(name: "MediaSourceId", value: itemId))      // Same as itemId typically
        queryItems.append(URLQueryItem(name: "PlaySessionId", value: UUID().uuidString))
        queryItems.append(URLQueryItem(name: "static", value: "false"))            // Not static (HLS)
        queryItems.append(URLQueryItem(name: "StreamOptions", value: "{\"RequireAvc\":true}"))
        
        components?.queryItems = queryItems
        
        print("Constructed manual HLS streaming URL: \(components?.url?.absoluteString ?? "Invalid URL")")
        return components?.url
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
         NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
             self.isPlaying = false
         }
         
         // Time observer
         let interval = CMTime(seconds: 1, preferredTimescale: 1)
         timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
             guard !self.isSeeking else { return }
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
    
    private func setupAVPlayer(with url: URL) {
        // Reset state if needed
        if player != nil {
            removePlayerObservers()
        }
        
        // Create new player
        let avPlayer = AVPlayer(url: url)
        self.player = avPlayer
        
        // Add observers
        addPlayerObservers(player: avPlayer)
        
        // Load duration
        Task {
            do {
                try await loadPlayerDuration(player: avPlayer)
                
                // Start playback automatically
                avPlayer.play()
                isPlaying = true
                scheduleControlsTimer()
                
                // Hide loading indicator
                isLoading = false
                print("Player setup complete, playback started.")
            } catch {
                print("Error loading player duration: \(error)")
                // Continue with playback even if duration can't be determined
                avPlayer.play()
                isPlaying = true
                isLoading = false
            }
        }
    }
    
    private func startPlaybackSession(itemId: String) {
        Task {
            do {
                // Generate a session ID
                let sessionId = UUID().uuidString
                
                // Report playback start to Jellyfin
                try await jellyfinService.reportPlaybackStart(
                    itemId: itemId,
                    sessionId: sessionId
                )
                
                print("Started playback session for item: \(itemId)")
            } catch {
                print("Failed to start playback session: \(error)")
                // Continue with playback even if session can't be reported
            }
        }
    }
    
    // Clean up observers when needed
    private func removePlayerObservers() {
        // Remove time observer
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    // Handle player item finishing
    @objc private func playerItemDidPlayToEndTime() {
        isPlaying = false
        if autoExitOnFinish {
            // Exit the player view
            presentationMode.wrappedValue.dismiss()
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