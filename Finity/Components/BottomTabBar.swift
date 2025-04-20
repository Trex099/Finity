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
    
    var body: some View {
        GeometryReader { geometry in
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
                    }
                    .accessibility(identifier: "tab_\(tab.rawValue)")
                }
            }
            .frame(width: geometry.size.width, height: 60)
            .background(Color.black.opacity(0.9))
            .overlay(
                Rectangle()
                    .frame(width: geometry.size.width, height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .frame(height: 60)
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        BottomTabBar(selectedTab: .constant(.home))
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}