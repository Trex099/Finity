import SwiftUI

struct TopNavigationBar: View {
    @Binding var selectedTab: NavigationTab
    @State private var showSearch = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: geometry.size.width * 0.04) {
                // App logo
                Text("FINITY")
                    .font(.system(size: min(22, geometry.size.width * 0.055), weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, min(16, geometry.size.width * 0.04))
                    .accessibility(identifier: "app_logo")
                
                // Navigation tabs on larger screens
                if geometry.size.width > 375 { // Only show tabs on larger screens
                    ForEach(NavigationTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.title)
                                .font(.system(size: min(16, geometry.size.width * 0.04)))
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                                .padding(.vertical, 8)
                                .frame(minWidth: 44, minHeight: 44)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(selectedTab == tab ? .white : .clear)
                                        .offset(y: 4),
                                    alignment: .bottom
                                )
                        }
                        .accessibility(identifier: "tab_\(tab.title)")
                    }
                }
                
                Spacer()
                
                // Search button
                Button(action: {
                    showSearch.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibility(identifier: "search_button")
                
                // Profile button
                Button(action: {}) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, min(16, geometry.size.width * 0.04))
                .accessibility(identifier: "profile_button")
            }
            .frame(width: geometry.size.width, height: 60)
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
        .frame(height: 60)
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
                        .frame(width: 44, height: 44)
                }
                .accessibility(identifier: "close_search_button")
                
                TextField("Search for movies, TV shows, or music...", text: $searchText)
                    .padding(10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.trailing)
                    .font(.system(size: 16))
                    .accessibility(identifier: "search_field")
            }
            .padding()
            
            Spacer()
            
            Text("Search results will appear here")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct TopNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TopNavigationBar(selectedTab: .constant(.home))
                .preferredColorScheme(.dark)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .previewDevice("iPhone 13 Pro")
            
            TopNavigationBar(selectedTab: .constant(.home))
                .preferredColorScheme(.dark)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .previewDevice("iPhone SE (3rd generation)")
        }
    }
} 