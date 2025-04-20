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
    // Total desired height of the visible blurred bar (including padding above/below icons)
    let totalBarHeight: CGFloat = 65

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    // Ensure content is centered within the button frame
                    .frame(height: totalBarHeight)
                }
                .accessibility(identifier: "tab_\(tab.rawValue)")
            }
        }
        // The HStack defines the visual height of the bar
        .frame(height: totalBarHeight)
        .background(BlurView(style: .systemMaterialDark)) // Background applied directly
        // No safe area handling here - container will manage placement
    }
}

// Keep BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = UIBlurEffect(style: style) }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            // Preview the bar appearance directly
            BottomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}