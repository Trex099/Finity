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
    let contentHeight: CGFloat = 50 // Height for icons/text area

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = contentHeight + geometry.safeAreaInsets.bottom
            
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
                        // Set frame height for content area only
                        .frame(height: contentHeight)
                    }
                    .accessibility(identifier: "tab_\(tab.rawValue)")
                }
            }
            // Position the HStack and apply background to total height
            .frame(width: geometry.size.width, height: totalHeight, alignment: .top) // Align content to top
            .padding(.bottom, geometry.safeAreaInsets.bottom) // This padding is effectively handled by the frame height now, can be removed or kept for clarity
            .background(BlurView(style: .systemMaterialDark))
        }
        // The GeometryReader itself should take the calculated total height
        .frame(height: contentHeight + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)) // Approximate height for preview
        .edgesIgnoringSafeArea(.bottom)
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