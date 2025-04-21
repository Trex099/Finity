import SwiftUI
import Combine
import MobileVLCKit  // For direct VLC types
// import VLCKitSPM  // Removed this import

struct MediaPlayerView_New: View {
    // Item details (passed in)
    let itemId: String
    let itemName: String

    // Services & Environment
    @EnvironmentObject var jellyfinService: JellyfinService
    @Environment(\.presentationMode) var presentationMode

    // Player State Manager (replaces individual @State variables for player)
    @StateObject private var playerManager = VideoPlayerManager()

    // UI State (Keep these)
    @State private var areControlsVisible: Bool = true
    @State private var controlsTimer: Timer?
    @State private var isSeeking: Bool = false // Still needed for slider interaction

    // Error message state (now potentially set by playerManager)
    @State private var errorMessage: String? // Keep for now, can be linked to playerManager.error

    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)

            // VLC Video Player View
            // Use our custom VLCPlayerView instead of VLCVideoPlayer
            VLCPlayerView(proxy: playerManager.proxy)
                .edgesIgnoringSafeArea(.all)
                // Add callbacks to update the playerManager
                .onTicksUpdated { time, _ in // Use the time provided by the callback
                    // Assuming time.intValue gives milliseconds
                    playerManager.onTicksUpdated(ticks: time.intValue)
                }
                .onStateUpdated { state, _ in // Use the state provided by the callback
                    playerManager.onStateUpdated(newState: state)
                }
                .onTapGesture {
                    withAnimation {
                        areControlsVisible.toggle()
                    }
                    if areControlsVisible {
                        scheduleControlsTimer()
                    }
                }

            // Controls Overlay (binds to playerManager)
            if areControlsVisible {
                VStack {
                    // Top bar (unchanged)
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title2).foregroundColor(.white).padding()
                        }
                        Text(itemName).foregroundColor(.white).lineLimit(1).padding(.horizontal)
                        Spacer()
                    }
                    .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]), startPoint: .top, endPoint: .bottom))

                    Spacer()

                    // Bottom controls (modified bindings)
                    VStack(spacing: 10) {
                        // Seek bar
                        HStack {
                            // Use playerManager.currentTimeSeconds
                            Text(formatTime(seconds: playerManager.currentTimeSeconds))
                                .foregroundColor(.white).font(.caption)

                            Slider(
                                // Bind slider value directly to playerManager.currentTimeSeconds
                                value: $playerManager.currentTimeSeconds,
                                // Use playerManager.totalDurationSeconds for the range
                                in: 0...(playerManager.totalDurationSeconds > 0 ? playerManager.totalDurationSeconds : 1.0), // Use 1.0 as fallback range if duration is 0
                                onEditingChanged: sliderEditingChanged
                            )
                            .accentColor(.white)

                            // Use playerManager.totalDurationSeconds
                            Text(formatTime(seconds: playerManager.totalDurationSeconds))
                                .foregroundColor(.white).font(.caption)
                        }
                        .padding(.horizontal)

                        // Playback controls (modified actions)
                        HStack {
                            Spacer()
                            Button(action: seekBackward) {
                                Image(systemName: "gobackward.10").font(.title).foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: togglePlayPause) {
                                // Use playerManager.isPlaying
                                Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50)).foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: seekForward) {
                                Image(systemName: "goforward.10").font(.title).foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.bottom)
                    }
                    .background(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
                }
                .transition(.opacity)
            }

            // Loading indicator (driven by playerManager state)
            if playerManager.state == .opening || playerManager.state == .buffering {
                ZStack {
                    Color.black.opacity(0.5)
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
                }
                .transition(.opacity) // Add transition
            }

            // Error message (driven by playerManager error or local error)
            if let errorToShow = errorMessage ?? playerManager.error?.localizedDescription {
                VStack {
                    Text("Playback Error").font(.headline).foregroundColor(.white).padding(.bottom, 4)
                    Text(errorToShow).foregroundColor(.white).multilineTextAlignment(.center)
                    Button("Dismiss") { presentationMode.wrappedValue.dismiss() }
                        .padding().background(Color.red).foregroundColor(.white).cornerRadius(8).padding(.top)
                }
                .padding().background(Color.black.opacity(0.8)).cornerRadius(12).padding()
                .transition(.opacity) // Add transition
            }
        }
        .statusBar(hidden: true)
        .onAppear(perform: setupPlayback)
        .onDisappear(perform: playerManager.cleanup) // Use manager's cleanup
        .onChange(of: playerManager.error != nil) { hasError in
            if hasError {
                // Update local error message if manager has a new error
                self.errorMessage = playerManager.error?.localizedDescription
            } // Optionally add an else clause to clear the message when playerManager.error becomes nil
        }
    }

    // MARK: - Playback Setup

    private func setupPlayback() {
        Task {
            do {
                // Use the static helper on VideoPlayerViewModel to create the instance
                let viewModel = try await VideoPlayerViewModel.create(
                    itemId: itemId,
                    itemName: itemName,
                    jellyfinService: jellyfinService
                )
                // Configure the manager with the created ViewModel
                playerManager.configure(with: viewModel)
                self.errorMessage = nil // Clear previous errors on successful setup
            } catch {
                print("Error setting up playback: \(error.localizedDescription)")
                // Set the error message state to display the error
                if let playerError = error as? PlayerError {
                    self.errorMessage = playerError.localizedDescription
                } else {
                    self.errorMessage = error.localizedDescription
                }
                // Ensure player state reflects error
                playerManager.error = error
            }
        }
    }

    // MARK: - Control Functions (Interact with playerManager.proxy)

    private func togglePlayPause() {
        playerManager.proxy.togglePause()
        if playerManager.isPlaying {
            // If toggling to pause, invalidate timer
            controlsTimer?.invalidate()
        } else {
            // If toggling to play, schedule timer
            scheduleControlsTimer()
        }
    }

    private func seekTo(time: Double) {
        // Convert seconds back to VLC's milliseconds Time object
        let targetTimeMs = Int32(time * 1000)
        let vlcTime = VLCTime(int: targetTimeMs)
        playerManager.proxy.seek(to: vlcTime)
    }

    private func seekBackward() {
        let currentTime = playerManager.currentTimeSeconds
        let newTime = max(0, currentTime - 10)
        seekTo(time: newTime)
        showControlsBriefly()
    }

    private func seekForward() {
        let currentTime = playerManager.currentTimeSeconds
        let newTime = min(playerManager.totalDurationSeconds, currentTime + 10) // Ensure not seeking beyond duration
        seekTo(time: newTime)
        showControlsBriefly()
    }

    // Called when slider interaction changes
    private func sliderEditingChanged(editingStarted: Bool) {
        isSeeking = editingStarted
        if editingStarted {
            // Pause playback while scrubbing? (Optional, depends on desired UX)
            // if playerManager.isPlaying { playerManager.proxy.pause() }
            controlsTimer?.invalidate() // Keep controls visible while scrubbing
        } else {
            // User finished scrubbing, perform the actual seek
            seekTo(time: playerManager.currentTimeSeconds)
            // Resume playback if it was playing before scrubbing? (Optional)
            // if playerManager.isPlaying { playerManager.proxy.play() }
            scheduleControlsTimer() // Restart timer after scrubbing
        }
    }

    // MARK: - UI Helpers

    private func scheduleControlsTimer() {
        controlsTimer?.invalidate()
        // Only schedule if currently playing
        if playerManager.isPlaying {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                // Check again in case state changed during the timer
                if playerManager.isPlaying {
                    withAnimation {
                        areControlsVisible = false
                    }
                }
            }
        }
    }

    // Helper to show controls for a moment after an action like seeking
    private func showControlsBriefly() {
        withAnimation {
            areControlsVisible = true
        }
        scheduleControlsTimer()
    }

    private func formatTime(seconds: Double) -> String {
        guard !seconds.isNaN, !seconds.isInfinite, seconds >= 0 else {
            return "--:--"
        }
        let totalSecondsInt = Int(seconds)
        let hours = totalSecondsInt / 3600
        let minutes = (totalSecondsInt % 3600) / 60
        let secs = totalSecondsInt % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// Remove the old AVPlayer related helpers/extensions if they exist below this point
// e.g., removePlayerObservers, loadPlayerDuration, playerItemDidPlayToEndTime, etc. 