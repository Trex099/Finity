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
    let barContentHeight: CGFloat = 55 // Fixed height for the icons/text area

    var body: some View {
        // HStack contains the buttons
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
                    // Ensure button content is centered and takes full width/height of the bar content area
                    .frame(maxWidth: .infinity)
                    .frame(height: barContentHeight)
                }
                .accessibility(identifier: "tab_\(tab.rawValue)")
            }
        }
        .frame(height: barContentHeight) // Set the fixed height for the content
        .background(BlurView(style: .systemMaterialDark)) // Apply background to the content area
        // Safe area padding will be applied by the container view
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.home))
                // Simulate safe area in preview
                .padding(.bottom, 34)
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark)
    }
}