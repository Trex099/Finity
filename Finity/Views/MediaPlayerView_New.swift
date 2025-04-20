import SwiftUI
import AVKit
import Combine

struct MediaPlayerView_New: View {
    // Item to play
    let itemId: String
    let itemName: String
    
    // Services
    @EnvironmentObject var jellyfinService: JellyfinService
    
    // Player state
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var currentTime: Double = 0
    @State private var totalDuration: Double = 0
    @State private var isSeeking: Bool = false
    @State private var areControlsVisible: Bool = true
    @State private var controlsTimer: Timer?
    @State private var timeObserverToken: Any?
    @State private var autoExitOnFinish = true
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Video player
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        areControlsVisible.toggle()
                    }
                    if areControlsVisible {
                        scheduleControlsTimer()
                    }
                }
            
            // Controls overlay
            if areControlsVisible {
                VStack {
                    // Top bar with back button and title
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Text(itemName)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 10) {
                        // Seek bar
                        HStack {
                            Text(formatTime(seconds: currentTime))
                                .foregroundColor(.white)
                                .font(.caption)
                            
                            Slider(
                                value: $currentTime,
                                in: 0...(totalDuration > 0 ? totalDuration : 100),
                                onEditingChanged: { editing in
                                    isSeeking = editing
                                    if !editing {
                                        seekTo(time: currentTime)
                                    }
                                }
                            )
                            .accentColor(.white)
                            
                            Text(formatTime(seconds: totalDuration))
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        // Playback controls
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                seekRelative(seconds: -10)
                            }) {
                                Image(systemName: "gobackward.10")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Play/Pause button
                            Button(action: togglePlayPause) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                seekRelative(seconds: 10)
                            }) {
                                Image(systemName: "goforward.10")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }
            
            // Loading indicator
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            
            // Error message
            if let error = errorMessage {
                VStack {
                    Text("Playback Error")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Button("Dismiss") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding()
            }
        }
        .onAppear {
            setupPlayer(itemId: itemId)
        }
        .onDisappear {
            // Clean up resources
            player?.pause()
            removePlayerObservers()
            controlsTimer?.invalidate()
        }
    }
    
    // MARK: - Control Functions
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            controlsTimer?.invalidate()
        } else {
            player?.play()
            isPlaying = true
            scheduleControlsTimer()
        }
    }
    
    private func seekTo(time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: targetTime) { finished in
            if finished {
                isSeeking = false
            }
        }
    }
    
    private func seekRelative(seconds: Double) {
        if let currentTime = player?.currentTime().seconds {
            let newTime = max(0, currentTime + seconds)
            seekTo(time: newTime)
        }
    }
    
    private func scheduleControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                areControlsVisible = false
            }
        }
    }
    
    private func formatTime(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Playback Setup
    
    // Setup playback from ItemId
    private func setupPlayer(itemId: String) {
        // Reset any existing state
        if let existingPlayer = self.player {
            existingPlayer.pause()
            removePlayerObservers()
            self.player = nil
        }
        
        // Show loading state
        isLoading = true
        
        // Fetch playback info from Jellyfin
        Task {
            do {
                let playbackInfo = try await jellyfinService.fetchPlaybackInfo(itemId: itemId)
                print("Got playback info with \(playbackInfo.mediaSources.count) media sources.")
                
                guard let primarySource = playbackInfo.mediaSources.first else {
                    throw NSError(domain: "PlayerSetupError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No media sources available."])
                }
                
                // Log media source information
                print("Primary source protocol: \(primarySource.protocol ?? "none"), path: \(primarySource.path ?? "none")")
                
                // First try to get a direct URL from the media source
                if let playUrl = constructPlaybackURL(source: primarySource, itemId: itemId) {
                    print("Using direct playback URL: \(playUrl.absoluteString)")
                    setupAVPlayer(with: playUrl)
                    startPlaybackSession(itemId: itemId)
                    return
                }
                
                // If direct playback fails, fallback to manual HLS URL construction
                print("Direct playback URL construction failed, trying manual HLS URL...")
                if let manualHLSUrl = constructManualHLSURL(itemId: itemId) {
                    print("Using manually constructed HLS URL: \(manualHLSUrl.absoluteString)")
                    setupAVPlayer(with: manualHLSUrl)
                    startPlaybackSession(itemId: itemId)
                    return
                }
                
                // If all methods fail
                throw NSError(domain: "PlayerSetupError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to construct playback URL."])
                
            } catch {
                // Handle errors
                print("Error setting up player: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // Helper function to construct the final URL
    private func constructPlaybackURL(source: MediaSourceInfo, itemId: String) -> URL? {
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
        
        // Construct base URL
        var baseURL = serverURL
        if baseURL.hasSuffix("/") {
            baseURL.removeLast()
        }
        
        // Construct full URL
        let urlString = "\(baseURL)/Videos/\(itemId)/stream.m3u8"
        
        guard var components = URLComponents(string: urlString) else {
            print("Error: Could not create URL components from \(urlString)")
            return nil
        }
        
        // Add transcoding parameters
        var queryItems = [
            URLQueryItem(name: "api_key", value: token),
            URLQueryItem(name: "deviceId", value: UIDevice.current.identifierForVendor?.uuidString ?? ""),
            URLQueryItem(name: "PlaySessionId", value: UUID().uuidString),
            URLQueryItem(name: "MediaSourceId", value: itemId),
            URLQueryItem(name: "videoCodec", value: "h264"),
            URLQueryItem(name: "audioCodec", value: "aac"),
            URLQueryItem(name: "maxAudioChannels", value: "2"),
            URLQueryItem(name: "RequireAvc", value: "true"),
            URLQueryItem(name: "TranscodingMaxAudioChannels", value: "2"),
            URLQueryItem(name: "h264-profile", value: "high,main,baseline"),
            URLQueryItem(name: "h264-level", value: "51"),
        ]
        
        components.queryItems = queryItems
        
        print("Constructed manual HLS streaming URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return components.url
    }
    
    // Helper functions for player setup
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
    
    // Start a playback session in Jellyfin
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
    
    // Add observer for player state changes
    private func addPlayerObservers(player: AVPlayer) {
        // Remove any existing observers
        removePlayerObservers()
        
        // Add time observer
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            self.currentTime = time.seconds
        }
        
        // Add notification observer for when item finishes playing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
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
    
    // Load player duration asynchronously
    private func loadPlayerDuration(player: AVPlayer) async throws {
        guard let playerItem = player.currentItem else {
            throw NSError(domain: "PlayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No player item"])
        }
        
        // Wait until the player item status is determined
        return try await withCheckedThrowingContinuation { continuation in
            let keyPath = \AVPlayerItem.status
            
            // Create observer for the status
            let statusObserver = playerItem.observe(keyPath) { item, _ in
                switch item.status {
                case .readyToPlay:
                    // Get duration when ready
                    let duration = item.duration
                    if CMTimeGetSeconds(duration).isFinite {
                        self.totalDuration = CMTimeGetSeconds(duration)
                    }
                    continuation.resume()
                    // Remove observer after status is determined
                    statusObserver.invalidate()
                    
                case .failed:
                    // Handle failure
                    let error = item.error ?? NSError(domain: "PlayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    continuation.resume(throwing: error)
                    statusObserver.invalidate()
                    
                default:
                    // Wait for a definitive status
                    break
                }
            }
        }
    }
} 