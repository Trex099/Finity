import Foundation
import Combine
import MobileVLCKit   // For VLCMediaPlayer, VLCMedia, etc.
// import VLCKitSPM   // Removed this import

// Adapted from Swiftfin's VideoPlayerManager
final class VideoPlayerManager: ObservableObject {

    // MARK: - Published Properties for UI Binding

    @Published var currentViewModel: VideoPlayerViewModel? = nil
    @Published var state: VLCVideoPlayer.State = .opening // Current player state
    @Published var isPlaying: Bool = false // Convenience for UI
    @Published var currentTimeSeconds: Double = 0
    @Published var totalDurationSeconds: Double = 0
    @Published var error: Error? = nil // For displaying errors

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()
    private var hasSentStart = false // Keep for playback reporting logic
    private var currentProgressWorkItem: DispatchWorkItem? // Keep for playback reporting logic

    // The proxy to interact with the underlying VLCVideoPlayer view
    let proxy: VLCVideoPlayer.Proxy = .init()

    // Service Dependencies (Inject if needed, or access via Environment)
    weak var jellyfinService: JellyfinService? // Made optional and weak

    // MARK: - Initialization

    init(jellyfinService: JellyfinService? = nil) { // Allow injecting service
        print("VideoPlayerManager initialized")
        self.jellyfinService = jellyfinService
    }

    // MARK: - Configuration

    func configure(with viewModel: VideoPlayerViewModel) {
        print("Configuring VideoPlayerManager with ViewModel for item: \(viewModel.itemID)")
        self.currentViewModel = viewModel
        self.error = nil
        self.currentTimeSeconds = 0
        self.totalDurationSeconds = 0
        self.state = .opening
        self.isPlaying = false
        self.hasSentStart = false // Reset reporting flag

        // Tell the proxy to play the new media. The view will observe state/time.
        proxy.playNewMedia(viewModel.vlcVideoPlayerConfiguration)

        // Start reporting shortly after configuration
        // reportPlaybackStart(itemId: viewModel.itemID)
    }

    // MARK: - Public Methods for View Callbacks

    // Called by the View when VLC reports time updates
    func onTicksUpdated(ticks: Int) { // Simplified, assuming VLCTime intValue is ticks in ms
        let newSeconds = Double(ticks) / 1000.0

        // Update published properties
        // Add checks if scrubbing is implemented
        self.currentTimeSeconds = newSeconds

        // Attempt to get duration once available (might be better to get from media itself)
        if self.totalDurationSeconds == 0, let durationMs = self.proxy.mediaPlayer?.media?.length.intValue, durationMs > 0 {
            self.totalDurationSeconds = Double(durationMs) / 1000.0
        }

        // TODO: Throttle progress reporting
        // reportPlaybackProgress()
    }

    // Called by the View when VLC reports state updates
    func onStateUpdated(newState: VLCVideoPlayer.State) {
        guard state != newState else { return }
        print("VLC Player State Changed in Manager: \(newState)")
        self.state = newState
        self.isPlaying = (newState == .playing)

        // Handle specific states for playback reporting etc.
        switch newState {
        case .playing:
            if !hasSentStart {
                hasSentStart = true
                // reportPlaybackStart(itemId: currentViewModel?.itemID)
            }
        case .paused:
            if hasSentStart {
                hasSentStart = false // Reset for next play
                // reportPlaybackPause()
            }
        case .stopped, .ended:
             // reportPlaybackStop(reason: newState == .ended ? "PlaybackFinished" : "PlaybackStopped")
             if newState == .ended {
                 // TODO: Add logic for finishing (e.g., dismiss, play next)
                 print("Playback ended logic here")
             }
             hasSentStart = false
        case .error:
            self.error = PlayerError.unknownError("VLC encountered an error.")
            // reportPlaybackStop(reason: "PlaybackError")
            hasSentStart = false
        case .opening, .buffering:
            break // Do nothing for transient states
        }
    }

    // MARK: - Playback Reporting (Refined Example Structure)

    /* // Uncomment and implement these fully
    private func reportPlaybackStart(itemId: String?) {
        guard let itemId = itemId, let jellyfinService = jellyfinService else { return }
        currentProgressWorkItem?.cancel() // Cancel previous reporting
        print("Reporting playback start for: \(itemId)")
        hasSentStart = true // Mark as started

        Task {
            do {
                let sessionId = currentViewModel?.playSessionID ?? UUID().uuidString // Use existing or generate
                try await jellyfinService.reportPlaybackStart(itemId: itemId, sessionId: sessionId)
                print("Reported playback START successfully for item: \(itemId)")

                // Schedule progress reporting
                scheduleProgressReport()
            } catch {
                print("Failed to report playback start: \(error)")
                hasSentStart = false // Reset if reporting failed
            }
        }
    }

    private func scheduleProgressReport() {
        currentProgressWorkItem?.cancel()
        let progressTask = DispatchWorkItem { [weak self] in
            self?.reportPlaybackProgress()
            // Schedule next report
            self?.scheduleProgressReport()
        }
        currentProgressWorkItem = progressTask
        // Report progress every 10 seconds (adjust interval as needed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: progressTask)
    }

    private func reportPlaybackProgress() {
        guard let jellyfinService = jellyfinService, let viewModel = currentViewModel, state == .playing else {
            currentProgressWorkItem?.cancel() // Stop reporting if not playing
            return
        }
        let currentTicks = Int64(currentTimeSeconds * 1_000_000) // Jellyfin uses 100ns ticks (10,000,000 per second)
        let sessionId = viewModel.playSessionID ?? "" // Need session ID

        print("Reporting playback progress at ticks: \(currentTicks)")
        Task {
            do {
                try await jellyfinService.reportPlaybackProgress(
                    itemId: viewModel.itemID,
                    sessionId: sessionId,
                    positionTicks: currentTicks,
                    isPlaying: true // Assuming it's playing if reporting progress
                )
                // print("Reported playback PROGRESS successfully")
            } catch {
                print("Failed to report playback progress: \(error)")
                 currentProgressWorkItem?.cancel() // Stop reporting on error
            }
        }
    }

    private func reportPlaybackPause() {
         guard let jellyfinService = jellyfinService, let viewModel = currentViewModel else { return }
         currentProgressWorkItem?.cancel() // Stop progress reporting
         let currentTicks = Int64(currentTimeSeconds * 1_000_000)
         let sessionId = viewModel.playSessionID ?? ""
         print("Reporting playback pause at ticks: \(currentTicks)")
         Task {
             do {
                 try await jellyfinService.reportPlaybackProgress(
                     itemId: viewModel.itemID,
                     sessionId: sessionId,
                     positionTicks: currentTicks,
                     isPlaying: false // Report as paused
                 )
                 print("Reported playback PAUSE successfully")
             } catch {
                 print("Failed to report playback pause: \(error)")
             }
         }
    }

    private func reportPlaybackStop(reason: String) {
         guard let jellyfinService = jellyfinService, let viewModel = currentViewModel else { return }
         currentProgressWorkItem?.cancel() // Stop progress reporting
         let currentTicks = Int64(currentTimeSeconds * 1_000_000)
         let sessionId = viewModel.playSessionID ?? ""
         print("Reporting playback stop ('\(reason)') at ticks: \(currentTicks)")
         Task {
             do {
                 try await jellyfinService.reportPlaybackStopped(
                     itemId: viewModel.itemID,
                     sessionId: sessionId,
                     positionTicks: currentTicks
                 )
                 print("Reported playback STOP successfully")
             } catch {
                 print("Failed to report playback stop: \(error)")
             }
         }
         hasSentStart = false // Ensure flag is reset
    }
    */

    // MARK: - Cleanup

    func cleanup() {
        print("Cleaning up VideoPlayerManager")
        currentProgressWorkItem?.cancel() // Cancel any pending reports
        // reportPlaybackStop(reason: "ViewDismissed") // Report stop on cleanup

        proxy.stop()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        currentViewModel = nil
        error = nil
        hasSentStart = false
    }

    deinit {
        cleanup()
        print("VideoPlayerManager deinitialized")
    }
} 