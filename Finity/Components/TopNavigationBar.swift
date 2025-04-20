import SwiftUI

struct TopNavigationBar: View {
    @Binding var selectedTab: NavigationTab
    @State private var showSearch = false
    
    var body: some View {
        HStack(spacing: 32) {
            // App logo
            Text("FINITY")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading)
            
            // Navigation tabs
            ForEach(NavigationTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.title)
                        .font(.headline)
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                        .padding(.vertical, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == tab ? .white : .clear)
                                .offset(y: 4),
                            alignment: .bottom
                        )
                }
            }
            
            Spacer()
            
            // Search button
            Button(action: {
                showSearch.toggle()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding(.trailing)
            
            // Profile button
            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(.trailing)
        }
        .frame(height: 60)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showSearch) {
            SearchView()
                .preferredColorScheme(.dark)
        }
    }
}

// Navigation tabs
enum NavigationTab: CaseIterable {
    case home
    case movies
    case tvShows
    case music
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .movies: return "Movies"
        case .tvShows: return "TV Shows"
        case .music: return "Music"
        }
    }
}

// Placeholder for search view
struct SearchView: View {
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding()
                }
                
                TextField("Search for movies, TV shows, or music...", text: $searchText)
                    .padding(10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.trailing)
            }
            .padding()
            
            Spacer()
            
            Text("Search results will appear here")
                .foregroundColor(.gray)
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct TopNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigationBar(selectedTab: .constant(.home))
            .preferredColorScheme(.dark)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
} 