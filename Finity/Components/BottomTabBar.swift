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
    let barContentHeight: CGFloat = 50 // Height for icons/text

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) { // Use VStack to push to bottom
                Spacer() // Pushes the HStack down

                HStack(spacing: 0) {
                    ForEach(TabItem.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                            }
                            .frame(width: geometry.size.width / CGFloat(TabItem.allCases.count))
                            .frame(height: barContentHeight) // Set fixed height for content area
                        }
                        .accessibility(identifier: "tab_\(tab.rawValue)")
                    }
                }
                .frame(width: geometry.size.width) // HStack takes full width
                .frame(height: barContentHeight)   // HStack has fixed content height
                .padding(.bottom, geometry.safeAreaInsets.bottom) // Pad content UP from bottom edge
                .background(BlurView(style: .systemMaterialDark)) // Apply background AFTER padding
            }
            .edgesIgnoringSafeArea(.bottom) // Allow VStack (and background) to go edge-to-edge
        }
        // Set approximate total height for the container view itself
        .frame(height: barContentHeight + 34) // Use estimate for safe area in container frame
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.blue) // Example background
        .preferredColorScheme(.dark)
    }
}