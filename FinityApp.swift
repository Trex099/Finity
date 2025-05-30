//
//  FinityApp.swift
//  Finity
//
//  Created by arsh on 20/04/25.
//

import SwiftUI

@main
struct FinityApp: App {
    @StateObject var authManager = AuthManager()
    @StateObject var serverDiscoveryService = ServerDiscoveryService()
    @StateObject var jellyfinService = JellyfinService()

    var body: some Scene {
        WindowGroup {
            // Pass the service down to the ContentView
            MainView()
                 .environmentObject(jellyfinService)
        }
    }
}

// You'll need to create this MainView or adapt your existing ContentView
// struct MainView: View {
//     @EnvironmentObject var jellyfinService: JellyfinService
//
//     var body: some View {
//         // Show loading indicator while checking auth state initially
//         if jellyfinService.isCheckingAuth { // Need to add this state to JellyfinService
//              ProgressView()
//         } else if jellyfinService.isAuthenticated {
//              // Assuming ContentNavigationView is your main tab/navigation structure
//              ContentNavigationView() // Pass environment object implicitly
//         } else {
//              LoginView(jellyfinService: jellyfinService) // Pass directly if needed, or use environment
//         }
//     }
// }

// We need to create a view that decides whether to show Login or the main content
// based on the jellyfinService.isAuthenticated state.
// Let's create a simple placeholder MainView for now.
struct MainView: View {
    @EnvironmentObject var jellyfinService: JellyfinService
    // Assuming ContentNavigationView exists and holds HomeView etc.
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        // Show loading indicator while checking auth state initially
         if jellyfinService.isCheckingAuth { // We will add this state
             ZStack {
                 Color.black.edgesIgnoringSafeArea(.all)
                 ProgressView().scaleEffect(1.5).tint(.white)
             }
         } else if jellyfinService.isAuthenticated {
             MainContentNavigationView() // Use the renamed view
                .environmentObject(navigationState)
         } else {
             LoginView(jellyfinService: jellyfinService) // Pass explicitly as LoginView uses @ObservedObject
         }
    }
}

// Placeholder for your main navigation structure after login
struct MainContentNavigationView: View {
     @EnvironmentObject var jellyfinService: JellyfinService
     @EnvironmentObject var navigationState: NavigationState // For managing search view state etc.

     // Use the @State properties needed by the TabView logic
     @State private var selectedTab: TabItem = .home
     // showSearchView is now managed by the navigationState EnvironmentObject
     // @State private var showSearchView = false 

     var body: some View {
         // --- PASTE THE CONTENT FROM ContentNavigationView.swift HERE --- 
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Use navigationState.showSearchView for bindings
                HomeView(showSearchView: $navigationState.showSearchView)
                    .tag(TabItem.home)
                    .environmentObject(jellyfinService)
                
                FavoritesView(showSearchView: $navigationState.showSearchView)
                    .tag(TabItem.favorites)
                    .environmentObject(jellyfinService)
                
                SettingsView(showSearchView: $navigationState.showSearchView)
                    .tag(TabItem.settings)
                    .environmentObject(jellyfinService)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            // Keep the padding added earlier
            .padding(.bottom, 60)
            
            // Custom bottom tab bar that matches iOS standard
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            
                            Text(tab.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(
                ZStack {
                    Color.black.opacity(0.8)
                    BlurView(style: .systemMaterialDark)
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
        // Use navigationState.showSearchView for the sheet presentation
        .sheet(isPresented: $navigationState.showSearchView) { 
            SearchView()
                .preferredColorScheme(.dark)
                .environmentObject(jellyfinService)
        }
         // --- END OF PASTED CONTENT --- 
     }
}

// Simple state object for navigation-related things like showing search
class NavigationState: ObservableObject {
    @Published var showSearchView = false
}
