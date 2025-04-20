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
    let barContentHeight: CGFloat = 60 // Increased content height slightly

    var body: some View {
        GeometryReader { geometry in // Use geometry ONLY for safe area bottom
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 24)) // Slightly larger icon
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .medium)) // Slightly smaller text
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: barContentHeight) // Content area height
                    }
                    .accessibility(identifier: "tab_\(tab.rawValue)")
                }
            }
            .frame(height: barContentHeight) // HStack has fixed content height
            .background(BlurView(style: .systemMaterialDark)) // Background covers content area
            .padding(.bottom, geometry.safeAreaInsets.bottom) // Pad the whole bar up
        }
         // Allow the GeometryReader (and thus the padded bar) to determine its own height
         // which will be barContentHeight + safeAreaInsets.bottom
        .edgesIgnoringSafeArea(.bottom) // Let the background potentially extend visually if needed by OS

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
            BottomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}