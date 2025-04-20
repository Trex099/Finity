# Finity - Jellyfin Frontend

A sleek, modern, and cinematic frontend for Jellyfin media server, inspired by Apple TV and Netflix.

## Features

- Dark theme with minimalist layout focusing on content
- Netflix-style horizontal scrolling rows for browsing content
- Cinematic full-screen media player with floating controls
- Smooth transitions and animations for a premium feel

## Setup

### Adding Media Assets

For the app to display properly, add the following image assets to your Assets.xcassets:

1. Open Assets.xcassets in Xcode
2. Create image sets with the following names:
   - `inception`
   - `strangerthings`
   - `darkknight`
   - `breakingbad`
   - `madmax`
   - `johnwick`
   - `got`
   - `mandalorian`

You can use any movie/TV show poster images for these assets or download sample images from movie databases.

### Configuring Jellyfin Connection

To connect to your Jellyfin server:

1. Open `JellyfinService.swift`
2. Update the initialization in `HomeView.swift` with your server details:

```swift
@StateObject private var jellyfinService = JellyfinService(
    baseURL: "https://your-jellyfin-server.com",
    apiKey: "your-api-key"
)
```

## Implementation Notes

- The current implementation uses mock data for demonstration
- For a full implementation, the `JellyfinService` would need to be expanded to make actual API calls to your Jellyfin server
- Media playback currently uses a sample video URL - in a production app, this would be replaced with the actual streaming URL from Jellyfin

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Future Enhancements

- Implement actual Jellyfin API integration
- Add user authentication
- Support for continue watching
- Add media details page
- Implement watchlist functionality
- Support for multiple user profiles 