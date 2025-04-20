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
                        .frame(maxHeight: .infinity)
                    }
                    .accessibility(identifier: "tab_\(tab.rawValue)")
                }
            }
            .frame(width: geometry.size.width, height: 60 + geometry.safeAreaInsets.bottom)
            .padding(.bottom, geometry.safeAreaInsets.bottom)
            .background(BlurView(style: .systemMaterialDark))
        }
        .frame(height: 60)
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.blue)
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark)
    }
}