import SwiftUI
import Combine

struct HomeView: View {
    // Access the shared JellyfinService from the environment
    @EnvironmentObject var jellyfinService: JellyfinService 
    
    // Local state mirroring the service's published data
    @State private var featuredItems: [MediaItem] = [] 
    @State private var continueWatchingItems: [MediaItem] = []
    @State private var recentlyAddedItems: [MediaItem] = []
    @State private var movieItems: [MediaItem] = []
    @State private var showItems: [MediaItem] = []
    
    @State private var selectedItemForNavigation: MediaItem? = nil
    @State private var showPlayer = false
    @Binding var showSearchView: Bool // Binding from ContentNavigationView
    
    // Store subscriptions to update local state from service
    @State private var cancellables = Set<AnyCancellable>()
    
    // REMOVE the hardcoded tempMovies
    /*
    private var tempMovies: [MediaItem] {
        // ... removed hardcoded data ...
    }
    */
   
    // REMOVE the hardcoded categories
    /*
    private var categories: [String] {
        // ... removed hardcoded data ...
    }
    */
    
    var body: some View {
        GeometryReader { geometry in
            // RE-ADD NavigationStack for NavigationLink in MediaRowView
            NavigationStack { 
                VStack(spacing: 0) {
                    // Top Title Bar (Static, with Logo and Search)
                    TopTitleBar(showSearchView: $showSearchView, showLogo: true, showSearchIcon: true)
                        // Removed padding here in previous step, keep it removed for now.
                        .background(Color.black.edgesIgnoringSafeArea(.top))
                    
                    // Show loading indicator over the whole scroll view if loading initial data
                    if jellyfinService.isLoadingData && featuredItems.isEmpty && continueWatchingItems.isEmpty && recentlyAddedItems.isEmpty && movieItems.isEmpty && showItems.isEmpty {
                         Spacer()
                         ProgressView().scaleEffect(1.5)
                         Spacer()
                    } else {
                        // Extracted ScrollView content
                        contentScrollView
                    }
                }
                .background(Color.black)
                // Navigation title managed by TopTitleBar, so keep this hidden
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                 // Fetch data and set up observers when the view appears
                .onAppear(perform: setupView)
                // RE-ADD Navigation Destination
                .navigationDestination(for: MediaItem.self) { item in
                    MediaDetailView(itemId: item.id) // Pass ID to detail view
                        .preferredColorScheme(.dark)
                        // Hide the default back button title if desired
                        .navigationBarTitle("", displayMode: .inline) 
                }
            // RE-ADD NavigationStack closing brace
             }
            .fullScreenCover(isPresented: $showPlayer, content: {
                 // Pass the selected item to the player view
                if let itemToPlay = selectedItemForNavigation { 
                     MediaPlayerView_New(item: itemToPlay)
                } else {
                    // Optional: Placeholder or error view if item is nil
                    Text("Error loading player").foregroundColor(.white)
                }
            })
            // Add alert modifier to show errors from the service
            .alert("Error", isPresented: Binding( 
                get: { jellyfinService.errorMessage != nil },
                set: { _ in jellyfinService.errorMessage = nil } // Clear error when dismissed
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(jellyfinService.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - Computed Views
    
    // Extracted main content ScrollView
    @ViewBuilder // Use ViewBuilder for potential conditional content inside
    private var contentScrollView: some View {
        // Note: GeometryReader context is lost here. If needed, pass size down.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) { // <-- CHANGE VStack to LazyVStack
                // Banner uses latestItems from service
                FeaturedBannerCarouselView(
                    items: featuredItems, // Use local state updated via onReceive
                    onItemSelected: { item in
                        // Set item for potential navigation (now handled by NavigationLink/Destination)
                        selectedItemForNavigation = item 
                    },
                    onPlaySelected: { item in
                        selectedItemForNavigation = item
                        showPlayer = true // Trigger fullscreen player
                    }
                )
                
                // --- Continue Watching Section --- 
                if !continueWatchingItems.isEmpty {
                    Text("Continue Watching")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(continueWatchingItems) { item in
                                // ContinueWatchingCard itself won't navigate now, but will have tap for play
                                ContinueWatchingCard(item: item)
                                     .onTapGesture {
                                         // Tap gesture will now trigger direct playback
                                         selectedItemForNavigation = item
                                         showPlayer = true
                                     }
                                     .accessibility(identifier: "continue_watching_\(item.id)")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 20)
                }
                
                // --- Recently Added Section --- 
                if !recentlyAddedItems.isEmpty {
                    Text("Recently Added")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20) // Add top spacing
                    
                    let row = MediaRow(title: "", items: recentlyAddedItems)
                    MediaRowView(row: row)
                         .accessibility(identifier: "media_row_recently_added")
                }
                
                // --- Movies Section --- 
                if !movieItems.isEmpty {
                    Text("Movies")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20) // Add top spacing
                    
                    let row = MediaRow(title: "", items: movieItems)
                    MediaRowView(row: row)
                         .accessibility(identifier: "media_row_movies")
                }
                
                // --- TV Shows Section --- 
                if !showItems.isEmpty {
                    Text("TV Shows")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20) // Add top spacing
                    
                    let row = MediaRow(title: "", items: showItems)
                    MediaRowView(row: row)
                         .accessibility(identifier: "media_row_shows")
                }
                
                // Use a fixed spacer or pass geometry size if needed
                Spacer(minLength: 100) // Adjust as needed, geometry.safeAreaInsets is not available here
            }
        }
    }

    // MARK: - Setup & Data Loading
    
    // Setup subscriptions and load initial data
    private func setupView() {
        // Subscribe to service publishers to update local state
        jellyfinService.$latestItems
            .receive(on: DispatchQueue.main)
            .sink { items in self.featuredItems = items }
            .store(in: &cancellables)
            
        jellyfinService.$continueWatchingItems
            .receive(on: DispatchQueue.main)
            .sink { items in self.continueWatchingItems = items }
            .store(in: &cancellables)
            
        // Subscribe to new publishers
        jellyfinService.$recentlyAddedItems
            .receive(on: DispatchQueue.main)
            .sink { items in self.recentlyAddedItems = items }
            .store(in: &cancellables)
            
        jellyfinService.$movieItems
            .receive(on: DispatchQueue.main)
            .sink { items in self.movieItems = items }
            .store(in: &cancellables)
            
        jellyfinService.$showItems
            .receive(on: DispatchQueue.main)
            .sink { items in self.showItems = items }
            .store(in: &cancellables)
            
        // Load data if featuredItems is empty (or adapt logic as needed)
        if featuredItems.isEmpty { loadData() }
    }
    
    // Function to trigger data loading in the service
    private func loadData() {
        print("HomeView: Requesting initial home data from JellyfinService...")
        // Call the consolidated fetch function in the service
        jellyfinService.fetchInitialHomeData()
    }
}

// Preview needs adjustment - requires EnvironmentObject
/*
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        @State var showSearch = false
        
        // Preview will fail without EnvironmentObject
        // Need to provide a mock JellyfinService
        Group {
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone 13 Pro")
                // .environmentObject(MockJellyfinService()) // Example
            
            HomeView(showSearchView: $showSearch)
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (3rd generation)")
                 // .environmentObject(MockJellyfinService()) // Example
        }
    }
} 
*/ 