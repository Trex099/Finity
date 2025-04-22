import SwiftUI
import MobileVLCKit

// A UIViewRepresentable wrapper for VLCMediaPlayer
struct VLCPlayerView: UIViewRepresentable {
    // The real VLCMediaPlayer instance
    let mediaPlayer: VLCMediaPlayer
    
    // Callback handlers
    var onTimeChanged: ((VLCTime) -> Void)?
    var onStateChanged: ((VLCMediaPlayerState) -> Void)?
    
    // Create from a proxy
    init(proxy: VLCVideoPlayer.Proxy) {
        // If the proxy doesn't have a mediaPlayer, create one
        if proxy.mediaPlayer == nil {
            proxy.mediaPlayer = VLCMediaPlayer()
        }
        self.mediaPlayer = proxy.mediaPlayer!
    }
    
    // Create the UIView that hosts the player
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Add the VLC video view as a subview
        if let videoView = mediaPlayer.drawable as? UIView {
            videoView.frame = view.bounds
            videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(videoView)
        } else {
            // Create a new drawable view if needed
            mediaPlayer.drawable = view
        }
        
        // Set up the delegate
        mediaPlayer.delegate = context.coordinator
        
        return view
    }
    
    // Update the view if needed
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update callbacks if needed
        context.coordinator.onTimeChanged = onTimeChanged
        context.coordinator.onStateChanged = onStateChanged
    }
    
    // Coordinator handles VLC delegate callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VLCMediaPlayerDelegate {
        var parent: VLCPlayerView
        var onTimeChanged: ((VLCTime) -> Void)?
        var onStateChanged: ((VLCMediaPlayerState) -> Void)?
        
        init(_ parent: VLCPlayerView) {
            self.parent = parent
            super.init()
        }
        
        // VLCMediaPlayerDelegate method
        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            if let player = aNotification.object as? VLCMediaPlayer {
                // player.time is not optional in the current SDK
                let time = player.time
                onTimeChanged?(time)
            }
        }
        
        // VLCMediaPlayerDelegate method
        func mediaPlayerStateChanged(_ aNotification: Notification) {
            if let player = aNotification.object as? VLCMediaPlayer {
                onStateChanged?(player.state)
            }
        }
    }
}

// Extension to add the modifiers similar to our mock VLCVideoPlayer
extension VLCPlayerView {
    // Add onTicksUpdated modifier
    func onTicksUpdated(_ handler: @escaping (VLCTime, Any?) -> Void) -> Self {
        var view = self
        view.onTimeChanged = { time in
            handler(time, nil)
        }
        return view
    }
    
    // Add onStateUpdated modifier, converting VLCMediaPlayerState to our VLCVideoPlayer.State
    func onStateUpdated(_ handler: @escaping (VLCVideoPlayer.State, Any?) -> Void) -> Self {
        var view = self
        view.onStateChanged = { vlcState in
            // Convert VLCMediaPlayerState to our VLCVideoPlayer.State
            let state: VLCVideoPlayer.State
            switch vlcState {
            case .opening:
                state = .opening
            case .buffering:
                state = .buffering
            case .playing:
                state = .playing
            case .paused:
                state = .paused
            case .stopped:
                state = .stopped
            case .ended:
                state = .ended
            case .error:
                state = .error
            default:
                // Handle any other states that might exist in the current VLC SDK
                print("Unhandled VLCMediaPlayerState: \(vlcState.rawValue)")
                state = .error
            }
            handler(state, nil)
        }
        return view
    }
} 