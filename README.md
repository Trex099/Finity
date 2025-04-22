# Finity - Jellyfin Frontend

A sleek, modern, and cinematic frontend for Jellyfin media server, inspired by Apple TV and Netflix.

## Features

- Dark theme with minimalist layout focusing on content
- Netflix-style horizontal scrolling rows for browsing content
- Bottom tab navigation with Home, Search, Favorites, and Settings
- Cinematic full-screen media player with floating controls
- Smooth transitions and animations for a premium feel
- Responsive design that adapts to all iPhone screen sizes
- Metallic FINITY logo showcasing premium branding

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

## Navigation Structure

The app uses a tab-based navigation system with four main tabs:

1. **Home** - Main browsing experience with featured content and media rows
2. **Search** - Search functionality with categories and filters
3. **Favorites** - User's saved favorite content
4. **Settings** - App configuration and user preferences

## Implementation Notes

- The current implementation uses mock data for demonstration
- For a full implementation, the `JellyfinService` would need to be expanded to make actual API calls to your Jellyfin server
- Media playback currently uses a sample video URL - in a production app, this would be replaced with the actual streaming URL from Jellyfin
- The UI is fully responsive and follows Apple's Human Interface Guidelines with proper sizing for all elements

## Responsive Design

- All UI components use GeometryReader to adapt to different screen sizes
- Minimum touch target sizes of 44x44 points following Apple's guidelines
- Dynamic text sizing that scales appropriately for different devices
- Bottom tab navigation for easier one-handed use on modern iPhones
- Volume controls conditionally appear based on available screen height

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