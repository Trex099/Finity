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
    let barContentHeight: CGFloat = 55 // Height for the actual icons/text area

    var body: some View {
        // HStack contains the buttons - NO background or complex framing here
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
                    .frame(maxWidth: .infinity)
                    // Content VStack is centered within this height
                    .frame(height: barContentHeight)
                }
                .accessibility(identifier: "tab_\(tab.rawValue)")
            }
        }
        // The HStack itself only defines the content area height
        .frame(height: barContentHeight)
        // Background and safe area padding are handled by the container
    }
}

// Keep BlurView definition if needed elsewhere, or remove if only used here
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct BottomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            // Preview the bar itself, padding applied in container
            BottomTabBar(selectedTab: .constant(.home))
                .background(BlurView(style: .systemMaterialDark)) // Add background for preview
                .padding(.bottom, 34) // Simulate safe area padding
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark)
    }
}