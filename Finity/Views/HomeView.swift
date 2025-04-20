import SwiftUI
import Combine

struct HomeView: View {
    // Access the shared JellyfinService from the environment
    @EnvironmentObject var jellyfinService: JellyfinService 
    
    // Local state mirroring the service's published data
    @State private var featuredItems: [MediaItem] = [] 
    @State private var continueWatchingItems: [MediaItem] = []
    // Keep recentlyAddedItems for now, though fetching logic isn't implemented yet
    @State private var recentlyAddedItems: [MediaItem] = [] 
    
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
            // REMOVED: NavigationStack allows push navigation
            // NavigationStack { 
                VStack(spacing: 0) {
                    // Top Title Bar (Static, with Logo and Search)
                    TopTitleBar(showSearchView: $showSearchView, showLogo: true, showSearchIcon: true)
                        .background(Color.black.edgesIgnoringSafeArea(.top))
                    
                    // Show loading indicator over the whole scroll view if loading initial data
                    if jellyfinService.isLoadingData && featuredItems.isEmpty && continueWatchingItems.isEmpty {
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
                // Define the destination for the NavigationLink based on the selected item
                // This needs rethinking now that NavigationStack is removed.
                // We might need to handle navigation differently (e.g., using sheets or changing tabs)
                /* .navigationDestination(for: MediaItem.self) { item in
                    MediaDetailView(itemId: item.id) // Pass ID to detail view
                        .preferredColorScheme(.dark)
                        // Hide the default back button title if desired
                        .navigationBarTitle("", displayMode: .inline) 
                }*/
            // REMOVED: NavigationStack closing brace
            // }
            .fullScreenCover(isPresented: $showPlayer, content: {
                 // Pass the selected item to the player view
                if let itemToPlay = selectedItemForNavigation { 
                     MediaPlayerView(item: itemToPlay)
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
                        // Navigation needs to be handled differently now.
                        // Option 1: Present MediaDetailView as a sheet.
                        // Option 2: Change to a different tab (less likely for details).
                        // Option 3: Use NavigationLink from MediaRowView if that *is* inside a NavStack.
                        selectedItemForNavigation = item 
                        // TODO: Decide how to present details - using sheet for now?
                        // Might need a @State var like showDetailSheet = false
                    },
                    onPlaySelected: { item in
                        selectedItemForNavigation = item
                        showPlayer = true
                    }
                )
                .padding(.bottom, 20)
                
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
                                ContinueWatchingCard(item: item)
                                     .onTapGesture {
                                         // Navigation needs to be handled differently.
                                         // Let's assume we want to show details. Present as sheet?
                                         selectedItemForNavigation = item
                                         // TODO: Trigger detail presentation (e.g., sheet)
                                     }
                                     .accessibility(identifier: "continue_watching_\(item.id)")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 20)
                }
                
                // --- Recently Added Section (Placeholder/Future) ---
                if !recentlyAddedItems.isEmpty {
                    Text("Recently Added")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Existing MediaRowView might need updates for new MediaItem structure
                    let row = MediaRow(title: "", items: recentlyAddedItems) // Title is now a separate Text view
                    // MediaRowView itself contains NavigationLinks. This might break without a NavStack.
                    // We need to decide the navigation pattern.
                    // If MediaRowView *needs* NavigationLinks, HomeView might need the NavStack back,
                    // OR MediaRowView needs to use a different presentation method (like buttons triggering sheets).
                    MediaRowView(row: row) // Removed selectedItem
                         .accessibility(identifier: "media_row_recently_added")
                         .padding(.bottom, 20)
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
            
        // TODO: Subscribe to recently added if implemented in service
        
        // Load data if needed (e.g., if lists are empty)
        if featuredItems.isEmpty { loadData() }
    }
    
    // Function to trigger data loading in the service
    private func loadData() {
        print("HomeView: Requesting data from JellyfinService...")
        jellyfinService.fetchLatestMedia(limit: 6) // Fetch 6 for banner
        jellyfinService.fetchContinueWatching()
        // TODO: Call fetchRecentlyAdded if implemented
        
        // Remove the old simulation logic
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // ... old simulated data ...
            print("Simulated data loaded.")
        }
        */
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