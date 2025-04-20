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
    // Height for the actual interactive content (icon + text)
    let contentAreaHeight: CGFloat = 50

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
                            .font(.system(size: 22)) // Adjusted icon size back
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium)) // Adjusted text size back
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    // Ensure content fits within the specified content height
                    .frame(height: contentAreaHeight)
                }
                .accessibility(identifier: "tab_\(tab.rawValue)")
            }
        }
        // HStack frame matches the content height
        .frame(height: contentAreaHeight)
        // Background is applied ONLY to the content height area
        .background(BlurView(style: .systemMaterialDark))
        // Container view (.safeAreaInset) will handle positioning and padding
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
            // Preview simulates how it might look in the inset
            BottomTabBar(selectedTab: .constant(.home))
                .padding(.vertical, 10) // Add example padding
                .padding(.bottom, 34) // Add example safe area
                .background(Color.black) // Add black behind for contrast

        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}