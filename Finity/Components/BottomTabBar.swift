import SwiftUI

enum TabItem: String, CaseIterable {
    case home = "Home"
    case favorites = "Favorites"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .favorites: return "heart.fill"
        case .settings: return "gear"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: TabItem
    let barContentHeight: CGFloat = 55 // Keep increased height

    var body: some View {
        GeometryReader { geometry in
            // Calculate total height required including safe area
            let totalHeight = barContentHeight + geometry.safeAreaInsets.bottom
            
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Spacer() // Push content down within the VStack
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            // Add padding *only* to the bottom of the VStack content
                            // Effectively pushing the content upwards relative to the bar's bottom edge
                            Spacer().frame(height: geometry.safeAreaInsets.bottom / 2) // Adjust spacing
                             // Add slightly less than full safe area padding inside

                        }
                        .frame(width: geometry.size.width / CGFloat(TabItem.allCases.count))
                        .frame(height: totalHeight) // Button takes full calculated height
                       // .padding(.bottom, geometry.safeAreaInsets.bottom) // Padding applied inside VStack now

                    }
                    .accessibility(identifier: "tab_\(tab.rawValue)")
                }
            }
            .frame(width: geometry.size.width, height: totalHeight) // HStack uses total height
            .background(BlurView(style: .systemMaterialDark).edgesIgnoringSafeArea(.bottom)) // Background ignores safe area
        }
        // The view container should have the final total height
        .frame(height: totalHeight)
        .edgesIgnoringSafeArea(.bottom)

    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.gray) // Use a different color to see safe area
        .preferredColorScheme(.dark)
    }
}